# 🌟 Tokenised Community Volunteering Rewards

A decentralized smart contract system for managing community volunteering activities and rewarding volunteers with Community Volunteer Tokens (CVT). Built on the Stacks blockchain using Clarity.

## 🎯 Overview

This smart contract enables communities to create volunteering opportunities, track volunteer hours, verify contributions, and automatically reward participants with fungible tokens. The system promotes community engagement through transparent, blockchain-based incentive mechanisms.

## ✨ Features

### 🏆 Core Functionality
- **Create Activities**: Organizations can create volunteering activities with customizable rewards
- **Volunteer Registration**: Community members can join activities and commit estimated hours  
- **Hour Tracking**: Activity organizers can log verified volunteer hours
- **Token Rewards**: Automatic minting and distribution of CVT tokens based on contributions
- **Reputation System**: Track volunteer statistics and build reputation scores

### 🔧 Administrative Features
- **Activity Verification**: Contract owner can verify legitimate activities
- **Category Multipliers**: Set reward multipliers for different activity categories
- **Flexible Configuration**: Adjustable base reward rates and system parameters

### 📊 Data Tracking
- **Volunteer Stats**: Total activities, hours, rewards, and reputation scores
- **Activity Metrics**: Participant counts, total hours, completion status
- **Organizer Permissions**: Track organizer credibility and activity creation history

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- Node.js and npm for running tests

### Installation
```bash
git clone <repository-url>
cd Tokenised-Community-Volunteering-Rewards
npm install
```

### Testing
```bash
clarinet check
npm test
```

## 💻 Usage

### For Activity Organizers

#### Create a New Activity
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards create-activity 
  "Beach Cleanup" 
  "Help clean up the local beach and protect marine life" 
  u50  ; 50 tokens per hour
  u1440  ; 24 hours duration in blocks  
  u20)   ; max 20 participants
```

#### Log Volunteer Hours
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards log-volunteer-hours 
  'SP1VOLUNTEER... 
  u1   ; activity ID
  u4)  ; 4 hours contributed
```

#### Complete Activity
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards complete-activity u1)
```

### For Volunteers

#### Join an Activity
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards join-activity 
  u1   ; activity ID
  u4)  ; estimated 4 hours
```

#### Claim Rewards
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards claim-reward u1)
```

### For Administrators

#### Verify Activity
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards verify-activity u1)
```

#### Set Category Multiplier
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards set-category-multiplier 
  "environmental" 
  u150)  ; 1.5x multiplier
```

## 📋 Read-Only Functions

### Get Activity Information
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards get-activity u1)
```

### Check Volunteer Stats
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards get-volunteer-stats 'SP1VOLUNTEER...)
```

### Calculate Potential Reward
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards calculate-reward u1 u4)
```

### Check Token Balance
```clarity
(contract-call? .Tokenised-Community-Volunteering-Rewards get-balance 'SP1ADDRESS...)
```

## 🏗️ Contract Architecture

### Data Structures
- **Activities Map**: Stores activity details, requirements, and status
- **Volunteer Records**: Tracks individual participation and rewards
- **Volunteer Stats**: Aggregated statistics and reputation scores
- **Organizer Permissions**: Manages organizer credibility and history
- **Activity Categories**: Configurable reward multipliers by category

### Token Economics
- **Symbol**: CVT (Community Volunteer Token)
- **Decimals**: 6
- **Supply**: Unlimited (minted based on verified contributions)
- **Base Reward**: 100 tokens per hour (configurable)

### Security Features
- **Access Control**: Role-based permissions for organizers and administrators
- **Verification System**: Multi-step verification for activities and hours
- **Double-Claim Prevention**: Ensures rewards can only be claimed once per activity
- **Activity Lifecycle**: Proper state management from creation to completion

## 🔒 Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Invalid activity |
| u102 | Activity not found |
| u103 | Invalid volunteer |
| u104 | Reward already claimed |
| u105 | Insufficient tokens |
| u106 | Invalid amount |
| u107 | Activity expired |
| u108 | Invalid duration |
| u109 | Not verified |
| u110 | Invalid multiplier |


## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.


Built with ❤️ for community empowerment and volunteer appreciation 🌍
