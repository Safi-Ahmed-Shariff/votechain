const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8003;
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:8002';
const VOTE_SECRET = process.env.VOTE_SECRET || 'votechain-dev-vote-secret';

const voteStore = [];
const usedTokens = new Set();

const VALID_CANDIDATES = [
  { id: 'C001', name: 'Candidate A', party: 'Party Alpha' },
  { id: 'C002', name: 'Candidate B', party: 'Party Beta' },
  { id: 'C003', name: 'Candidate C', party: 'Party Gamma' },
  { id: 'C004', name: 'Candidate D', party: 'Party Delta' },
];

function encryptVote(candidateId, voterId) {
  const payload = JSON.stringify({
    candidate_id: candidateId,
    voter_id: voterId,
    timestamp: Date.now(),
    nonce: uuidv4(),
  });

  const cipher = crypto.createCipher('aes-256-cbc', VOTE_SECRET);
  let encrypted = cipher.update(payload, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}

function generateVoteHash(encryptedVote, token) {
  return crypto
    .createHmac('sha256', VOTE_SECRET)
    .update(encryptedVote + token)
    .digest('hex');
}

function createVoteBlock(voterId, candidateId, token) {
  const encryptedVote = encryptVote(candidateId, voterId);
  const voteHash = generateVoteHash(encryptedVote, token);
  const previousHash = voteStore.length > 0
    ? voteStore[voteStore.length - 1].hash
    : '0000000000000000';

  return {
    block_id: uuidv4(),
    hash: voteHash,
    previous_hash: previousHash,
    encrypted_vote: encryptedVote,
    timestamp: Date.now(),
    block_number: voteStore.length + 1,
  };
}

async function validateTokenWithAuthService(token) {
  try {
    const response = await axios.post(
      `${AUTH_SERVICE_URL}/validate-token`,
      { token },
      { timeout: 5000 }
    );
    return response.data.valid === true;
  } catch (error) {
    console.error('[VOTE] Auth service validation failed:', error.message);
    return false;
  }
}

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'vote-service',
    version: '0.1.0',
    total_votes: voteStore.length,
    timestamp: Date.now(),
  });
});

app.get('/candidates', (req, res) => {
  res.json({
    candidates: VALID_CANDIDATES,
    total: VALID_CANDIDATES.length,
    timestamp: Date.now(),
  });
});

app.post('/cast', async (req, res) => {
  const { voter_id, candidate_id, token } = req.body;

  if (!voter_id || !candidate_id || !token) {
    return res.status(400).json({
      error: 'MISSING_FIELDS',
      message: 'voter_id, candidate_id and token are all required',
    });
  }

  const validCandidate = VALID_CANDIDATES.find(c => c.id === candidate_id);
  if (!validCandidate) {
    return res.status(400).json({
      error: 'INVALID_CANDIDATE',
      message: `Candidate ${candidate_id} does not exist in this election`,
    });
  }

  if (usedTokens.has(token)) {
    console.warn(`[VOTE] Reused token attempt from voter: ${voter_id}`);
    return res.status(403).json({
      error: 'TOKEN_ALREADY_USED',
      message: 'This token has already been used to cast a vote',
    });
  }

  console.log(`[VOTE] Validating token with auth service for voter: ${voter_id}`);
  const tokenValid = await validateTokenWithAuthService(token);

  if (!tokenValid) {
    return res.status(401).json({
      error: 'INVALID_TOKEN',
      message: 'Token validation failed. Vote rejected.',
    });
  }

  const voteBlock = createVoteBlock(voter_id, candidate_id, token);
  voteStore.push(voteBlock);
  usedTokens.add(token);

  console.log(`[VOTE] Vote recorded. Block #${voteBlock.block_number} — Hash: ${voteBlock.hash.slice(0, 16)}...`);

  res.status(201).json({
    success: true,
    message: 'Vote recorded on blockchain',
    receipt: {
      block_number: voteBlock.block_number,
      vote_hash: voteBlock.hash,
      timestamp: voteBlock.timestamp,
    },
  });
});

app.get('/chain', (req, res) => {
  const chain = voteStore.map(block => ({
    block_number: block.block_number,
    block_id: block.block_id,
    hash: block.hash,
    previous_hash: block.previous_hash,
    timestamp: block.timestamp,
  }));

  res.json({
    total_blocks: chain.length,
    chain,
    timestamp: Date.now(),
  });
});

app.get('/stats', (req, res) => {
  res.json({
    total_votes_cast: voteStore.length,
    total_candidates: VALID_CANDIDATES.length,
    chain_length: voteStore.length,
    service: 'vote-service',
    timestamp: Date.now(),
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[VOTE] Vote service running on port ${PORT}`);
  console.log(`[VOTE] Auth service URL: ${AUTH_SERVICE_URL}`);
});
