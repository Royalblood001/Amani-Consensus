# Amani Consensus Network

> *Harmonizing blockchain consensus through collaborative mining*

## Overview

The Amani Consensus Network is a sophisticated blockchain infrastructure designed to coordinate distributed mining operations while ensuring fair reward distribution. Built on Stacks blockchain technology using Clarity smart contracts, Amani creates a secure, transparent environment where miners collaborate to maintain network consensus.

## Core Principles

- **Collaborative Consensus**: Miners work together toward network stability
- **Equitable Rewards**: Fair distribution based on verifiable contributions
- **Transparent Operations**: All activities recorded on-chain for accountability
- **Economic Security**: Stake-based participation prevents abuse
- **Efficient Coordination**: Automated assignment and verification processes

## System Architecture

The Amani Consensus Network operates through a carefully designed smart contract system with the following components:

### Network Infrastructure

- **Coordinator Management**: Privileged functions for network administration
- **Activity Controls**: Network can be activated or paused as needed
- **Parameter Configuration**: Adjustable difficulty and stake requirements
- **Chain Synchronization**: Height tracking for timeout enforcement

### Mining Framework

- **Block Registry**: Structured storage of mining challenges
- **Solution Verification**: On-chain validation of submitted solutions
- **Timeout Mechanisms**: Ensures network progress despite inactive miners
- **Reward Distribution**: Automatic payment upon successful mining

### Participant Management

- **Miner Profiles**: Comprehensive tracking of participant activities
- **Performance Metrics**: Historical data on mining success rates
- **Stake Management**: Secure handling of participant deposits
- **Activity Monitoring**: Timestamps for all participant interactions

## Technical Implementation

The Amani Consensus Network is implemented as a Clarity smart contract with the following key components:

### Data Structures

- **Block Registry**: Maps block IDs to mining parameters and status
- **Miner Profiles**: Tracks individual miner performance and assignments
- **Mining Records**: Documents attempts and successes for each block
- **Success History**: Maintains timestamps of successful mining operations

### Core Functions

#### Network Administration
- `activate-network()`: Enables mining operations
- `deactivate-network()`: Temporarily suspends network activities
- `update-stake-requirement()`: Adjusts minimum participation stake
- `update-chain-height()`: Synchronizes with blockchain progress

#### Block Management
- `register-block()`: Creates new mining opportunities
- `get-block-target()`: Provides mining parameters for specific blocks
- `get-mining-history()`: Returns historical data for completed blocks

#### Miner Operations
- `register-as-miner()`: Onboards new participants with required stake
- `submit-solution()`: Processes and verifies mining solutions
- `get-miner-status()`: Provides current status of registered miners
- `get-miner-history()`: Returns historical performance for specific miners

#### Financial Operations
- `withdraw-funds()`: Allows coordinator to manage network funds
- `refund-stake()`: Returns stake to departing miners

## Participation Guide

### For Miners

1. **Registration**:
   - Ensure you have sufficient STX tokens for staking
   - Call `register-as-miner()` to join the network
   - Your miner profile will be created automatically

2. **Mining Operations**:
   - Query available blocks using `get-block-target()`
   - Compute solutions based on the provided target hash
   - Submit solutions via `submit-solution()`
   - Receive rewards automatically upon successful verification

3. **Performance Monitoring**:
   - Track your status with `get-miner-status()`
   - Review historical performance via `get-miner-history()`
   - Monitor network statistics using `get-network-stats()`

### For Network Coordinators

1. **Network Management**:
   - Initialize the network with `activate-network()`
   - Register mining blocks using `register-block()`
   - Update chain height regularly with `update-chain-height()`
   - Adjust stake requirements as needed via `update-stake-requirement()`

2. **Administrative Tasks**:
   - Monitor network performance through `get-network-stats()`
   - Manage funds using `withdraw-funds()` when necessary
   - Process stake refunds with `refund-stake()` for departing miners
   - Pause the network with `deactivate-network()` during maintenance

## Security Considerations

- **Coordinator Privileges**: The network coordinator has administrative control
- **Economic Security**: Stake requirements prevent Sybil attacks
- **Timeout Protection**: Block timeouts ensure network progress
- **On-Chain Verification**: All solutions are verified transparently
- **Parameter Validation**: Input validation prevents invalid operations

## Technical Specifications

- **Platform**: Stacks Blockchain
- **Language**: Clarity Smart Contract Language
- **Minimum Stake**: 1,000,000 microSTX (1 STX)
- **Maximum Block ID**: 100
- **Mining History**: Stores up to 10 successful miners per block
- **Miner Profile**: Tracks up to 20 most recent mined blocks per miner

## Roadmap

- **Phase 1**: Initial deployment and testing
- **Phase 2**: Implementation of dynamic difficulty adjustment
- **Phase 3**: Introduction of delegated mining capabilities
- **Phase 4**: Development of governance mechanisms
- **Phase 5**: Integration with cross-chain consensus protocols