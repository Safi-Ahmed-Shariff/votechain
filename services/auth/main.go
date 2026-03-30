package main

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

type EligibilityRequest struct {
	VoterID      string `json:"voter_id"`
	BiometricRef string `json:"biometric_ref"`
}

type VoteTokenRequest struct {
	VoterID      string `json:"voter_id"`
	BiometricRef string `json:"biometric_ref"`
}

type AuthResponse struct {
	Success   bool   `json:"success"`
	VoterID   string `json:"voter_id"`
	Message   string `json:"message"`
	Token     string `json:"token,omitempty"`
	Timestamp int64  `json:"timestamp"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

var (
	voterRegistry = map[string]bool{
		"VTR-001-MH": true,
		"VTR-002-KA": true,
		"VTR-003-DL": true,
		"VTR-004-TN": true,
		"VTR-005-WB": true,
	}

	votedVoters = make(map[string]bool)
	votedMutex  sync.RWMutex

	issuedTokens = make(map[string]string)
	tokenMutex   sync.RWMutex

	tokenSecret = os.Getenv("TOKEN_SECRET")
)

func init() {
	if tokenSecret == "" {
		tokenSecret = "votechain-dev-secret-changeme"
	}
}

func generateToken(voterID string) (string, error) {
	randomBytes := make([]byte, 32)
	_, err := rand.Read(randomBytes)
	if err != nil {
		return "", err
	}

	timestamp := fmt.Sprintf("%d", time.Now().Unix())
	payload := voterID + ":" + timestamp + ":" + hex.EncodeToString(randomBytes)

	mac := hmac.New(sha256.New, []byte(tokenSecret))
	mac.Write([]byte(payload))
	signature := hex.EncodeToString(mac.Sum(nil))

	token := hex.EncodeToString([]byte(payload)) + "." + signature
	return token, nil
}

func verifyToken(token string) bool {
	tokenMutex.RLock()
	defer tokenMutex.RUnlock()
	for _, stored := range issuedTokens {
		if stored == token {
			return true
		}
	}
	return false
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, errCode, message string) {
	writeJSON(w, status, ErrorResponse{
		Error:   errCode,
		Message: message,
	})
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"status":    "healthy",
		"service":   "auth-service",
		"version":   "0.1.0",
		"timestamp": time.Now().Unix(),
	})
}

func eligibilityHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Use POST")
		return
	}

	var req EligibilityRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "INVALID_REQUEST", "Invalid JSON body")
		return
	}

	if req.VoterID == "" {
		writeError(w, http.StatusBadRequest, "MISSING_VOTER_ID", "voter_id is required")
		return
	}

	log.Printf("[AUTH] Eligibility check for voter: %s", req.VoterID)

	if !voterRegistry[req.VoterID] {
		log.Printf("[AUTH] Voter not found in registry: %s", req.VoterID)
		writeError(w, http.StatusNotFound, "VOTER_NOT_REGISTERED",
			fmt.Sprintf("Voter %s is not in the electoral roll", req.VoterID))
		return
	}

	votedMutex.RLock()
	alreadyVoted := votedVoters[req.VoterID]
	votedMutex.RUnlock()

	if alreadyVoted {
		log.Printf("[AUTH] DOUBLE VOTE ATTEMPT: %s", req.VoterID)
		writeError(w, http.StatusForbidden, "ALREADY_VOTED",
			"This voter has already cast their vote in this election")
		return
	}

	log.Printf("[AUTH] Voter %s is eligible", req.VoterID)
	writeJSON(w, http.StatusOK, AuthResponse{
		Success:   true,
		VoterID:   req.VoterID,
		Message:   "Voter is eligible to vote",
		Timestamp: time.Now().Unix(),
	})
}

func issueTokenHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Use POST")
		return
	}

	var req VoteTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "INVALID_REQUEST", "Invalid JSON body")
		return
	}

	if req.VoterID == "" {
		writeError(w, http.StatusBadRequest, "MISSING_VOTER_ID", "voter_id is required")
		return
	}

	log.Printf("[AUTH] Token request for voter: %s", req.VoterID)

	if !voterRegistry[req.VoterID] {
		writeError(w, http.StatusNotFound, "VOTER_NOT_REGISTERED",
			fmt.Sprintf("Voter %s is not in the electoral roll", req.VoterID))
		return
	}

	votedMutex.RLock()
	alreadyVoted := votedVoters[req.VoterID]
	votedMutex.RUnlock()

	if alreadyVoted {
		writeError(w, http.StatusForbidden, "ALREADY_VOTED",
			"Token already issued and vote already cast")
		return
	}

	tokenMutex.RLock()
	existingToken, hasToken := issuedTokens[req.VoterID]
	tokenMutex.RUnlock()

	if hasToken {
		writeJSON(w, http.StatusOK, AuthResponse{
			Success:   true,
			VoterID:   req.VoterID,
			Message:   "Token already issued — use existing token",
			Token:     existingToken,
			Timestamp: time.Now().Unix(),
		})
		return
	}

	token, err := generateToken(req.VoterID)
	if err != nil {
		log.Printf("[AUTH] Token generation failed for %s: %v", req.VoterID, err)
		writeError(w, http.StatusInternalServerError, "TOKEN_GENERATION_FAILED",
			"Failed to generate vote token")
		return
	}

	tokenMutex.Lock()
	issuedTokens[req.VoterID] = token
	tokenMutex.Unlock()

	votedMutex.Lock()
	votedVoters[req.VoterID] = true
	votedMutex.Unlock()

	log.Printf("[AUTH] Token issued for voter: %s", req.VoterID)

	writeJSON(w, http.StatusCreated, AuthResponse{
		Success:   true,
		VoterID:   req.VoterID,
		Message:   "Vote token issued. Voter marked as voted.",
		Token:     token,
		Timestamp: time.Now().Unix(),
	})
}

func validateTokenHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Use POST")
		return
	}

	var body map[string]string
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "INVALID_REQUEST", "Invalid JSON body")
		return
	}

	token, exists := body["token"]
	if !exists || token == "" {
		writeError(w, http.StatusBadRequest, "MISSING_TOKEN", "token is required")
		return
	}

	if !verifyToken(token) {
		writeError(w, http.StatusUnauthorized, "INVALID_TOKEN",
			"Token is invalid or was not issued by this service")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"valid":     true,
		"message":   "Token is valid",
		"timestamp": time.Now().Unix(),
	})
}

func statsHandler(w http.ResponseWriter, r *http.Request) {
	votedMutex.RLock()
	totalVoted := len(votedVoters)
	votedMutex.RUnlock()

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"total_registered": len(voterRegistry),
		"total_voted":      totalVoted,
		"remaining":        len(voterRegistry) - totalVoted,
		"service":          "auth-service",
		"timestamp":        time.Now().Unix(),
	})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8002"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/eligibility", eligibilityHandler)
	mux.HandleFunc("/issue-token", issueTokenHandler)
	mux.HandleFunc("/validate-token", validateTokenHandler)
	mux.HandleFunc("/stats", statsHandler)

	log.Printf("[AUTH] Auth service starting on port %s", port)

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("[AUTH] Server failed to start: %v", err)
	}
}
