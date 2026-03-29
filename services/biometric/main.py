import hashlib
import hmac
import os
import time
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s"
)
logger = logging.getLogger("biometric-service")

app = FastAPI(
    title="VoteChain Biometric Service",
    description="Handles fingerprint and iris hashing. Raw biometrics never stored.",
    version="0.1.0"
)

BIOMETRIC_PEPPER = os.getenv("BIOMETRIC_PEPPER", "votechain-dev-pepper-changeme")

biometric_store: dict[str, str] = {}
voted_registry: set[str] = set()


class BiometricEnrollRequest(BaseModel):
    voter_id: str = Field(..., min_length=6, max_length=50)
    fingerprint_data: str = Field(..., min_length=10)
    iris_data: str = Field(..., min_length=10)
    liveness_score: float = Field(..., ge=0.0, le=1.0)


class BiometricVerifyRequest(BaseModel):
    voter_id: str = Field(..., min_length=6, max_length=50)
    fingerprint_data: str = Field(..., min_length=10)
    iris_data: str = Field(..., min_length=10)
    liveness_score: float = Field(..., ge=0.0, le=1.0)


class BiometricResponse(BaseModel):
    success: bool
    voter_id: str
    message: str
    biometric_hash: Optional[str] = None
    timestamp: float


def generate_biometric_hash(voter_id: str, fingerprint_data: str, iris_data: str) -> str:
    combined = f"{voter_id}::{fingerprint_data}::{iris_data}::{BIOMETRIC_PEPPER}"
    biometric_hmac = hmac.new(
        key=BIOMETRIC_PEPPER.encode("utf-8"),
        msg=combined.encode("utf-8"),
        digestmod=hashlib.sha3_512
    )
    return biometric_hmac.hexdigest()


def check_liveness(liveness_score: float, voter_id: str) -> bool:
    LIVENESS_THRESHOLD = 0.80
    if liveness_score < LIVENESS_THRESHOLD:
        logger.warning(f"Liveness FAILED for voter {voter_id}. Score: {liveness_score}")
        return False
    return True


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "biometric-service",
        "version": "0.1.0",
        "timestamp": time.time()
    }


@app.post("/enroll", response_model=BiometricResponse, status_code=status.HTTP_201_CREATED)
def enroll_voter(request: BiometricEnrollRequest):
    logger.info(f"Enrollment request for voter: {request.voter_id}")

    if not check_liveness(request.liveness_score, request.voter_id):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": "LIVENESS_CHECK_FAILED",
                "message": "Biometric scanner detected possible spoofing attempt.",
                "liveness_score": request.liveness_score
            }
        )

    if request.voter_id in biometric_store:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error": "ALREADY_ENROLLED",
                "message": f"Voter {request.voter_id} is already enrolled."
            }
        )

    biometric_hash = generate_biometric_hash(
        request.voter_id,
        request.fingerprint_data,
        request.iris_data
    )

    biometric_store[request.voter_id] = biometric_hash
    logger.info(f"Voter {request.voter_id} enrolled. Hash: {biometric_hash[:16]}...")

    return BiometricResponse(
        success=True,
        voter_id=request.voter_id,
        message="Biometric enrolled successfully. Raw data discarded.",
        biometric_hash=biometric_hash,
        timestamp=time.time()
    )


@app.post("/verify", response_model=BiometricResponse)
def verify_voter(request: BiometricVerifyRequest):
    logger.info(f"Verification request for voter: {request.voter_id}")

    if not check_liveness(request.liveness_score, request.voter_id):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": "LIVENESS_CHECK_FAILED",
                "message": "Possible spoofing attempt detected."
            }
        )

    if request.voter_id not in biometric_store:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "error": "VOTER_NOT_ENROLLED",
                "message": f"Voter {request.voter_id} not found in biometric registry."
            }
        )

    if request.voter_id in voted_registry:
        logger.warning(f"DOUBLE VOTE ATTEMPT: voter {request.voter_id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "ALREADY_VOTED",
                "message": "This voter has already cast their vote."
            }
        )

    incoming_hash = generate_biometric_hash(
        request.voter_id,
        request.fingerprint_data,
        request.iris_data
    )
    stored_hash = biometric_store[request.voter_id]

    if not hmac.compare_digest(incoming_hash, stored_hash):
        logger.warning(f"Biometric mismatch for voter: {request.voter_id}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "BIOMETRIC_MISMATCH",
                "message": "Biometric verification failed."
            }
        )

    voted_registry.add(request.voter_id)
    logger.info(f"Voter {request.voter_id} verified successfully.")

    return BiometricResponse(
        success=True,
        voter_id=request.voter_id,
        message="Biometric verified. Voter authenticated.",
        timestamp=time.time()
    )


@app.get("/stats")
def get_stats():
    return {
        "total_enrolled": len(biometric_store),
        "total_verified_today": len(voted_registry),
        "service": "biometric-service",
        "timestamp": time.time()
    }
