# 🍼 Farbaby - Web3 Virtual Baby Care Game

![Farbaby Banner](https://via.placeholder.com/800x200/FF69B4/FFFFFF?text=Farbaby+-+Raise+Virtual+Babies+on+Farcaster)

## 🌟 Overview

**Farbaby** is a revolutionary Web3 virtual pet game built on the Farcaster social network where players cooperatively raise digital babies over the course of a full year. Unlike traditional virtual pet games, Farbaby requires **real commitment** with permanent consequences - neglect your baby and it dies forever.

### 🎯 Key Features

- **12-Month Journey**: Each baby grows from newborn to child over 52 real days (1 day = 1 week game time)
- **Cooperative Parenting**: Cannot hatch a baby alone - requires 2-4 co-parents for realistic family dynamics
- **Real Consequences**: Babies can permanently die from starvation, neglect, or poor health
- **Farcaster Integration**: Built natively on Farcaster with Frame-based interactions
- **NFT Babies**: Each baby is a unique NFT with genetic traits and appearance
- **Social Gameplay**: Family systems, community child services, and shared responsibilities

## 🎮 How to Play

### 1. **Registration**
```
Connect wallet → Register with nickname → Choose optional gender
```

### 2. **Create a Baby**
- Find 1-3 co-parents (required!)
- Create baby with name and 10-character appearance string
- Pay hatching fee (free with co-parents, 0.01 ETH solo)
- Wait 3 days for baby to hatch

### 3. **Daily Care**
- **Feed every 2 days** or baby starts losing health
- **Monitor health, happiness, intelligence, social stats**
- **Perform activities**: school, playdates, grandma visits
- **Coordinate with co-parents** for 24/7 care coverage

### 4. **Watch Them Grow**
- **Newborn** (Weeks 1-4): High maintenance, basic needs
- **Infant** (Weeks 5-12): Crawling, first interactions
- **Toddler** (Weeks 13-26): Walking, talking, tantrums
- **Preschooler** (Weeks 27-39): School preparation
- **Young Child** (Weeks 40-52): Complex activities and personality

## 🏗️ Technical Architecture

### Smart Contract System
- **Upgradeable Proxy Pattern** for continuous feature additions
- **ERC-721 NFTs** for unique baby ownership
- **Multi-signature parenting** with permission systems
- **Time-based mechanics** with real consequences

### Key Contracts
```
FarbabyGameV1.sol     - Main game logic (upgradeable)
FarbabyProxy.sol      - Proxy contract for upgrades
```

### Blockchain Details
- **Network**: Celo (low fees for microtransactions)
- **Standards**: ERC-721, ERC-1967 (proxy)
- **Upgradeable**: Yes, using OpenZeppelin UUPS pattern

## 📊 Game Mechanics

### Baby Stats (0-100)
- **Health**: Physical wellbeing, survival
- **Happiness**: Emotional state, affects growth
- **Intelligence**: Learning ability, unlocks activities
- **Social**: Interaction skills, family bonding
- **Energy**: Daily activity capacity
- **Hunger**: Critical survival stat
- **Hygiene**: Cleanliness, affects health

### Activities & Costs
| Activity | Cost | Effects | Required Stage |
|----------|------|---------|----------------|
| Normal Food | 0.001 ETH | +5 Health, +5 Happiness | Newborn |
| Premium Food | 1 ETH | +25 Health, +20 Happiness, +5 Intelligence | Newborn |
| School | 0.1 ETH | +20 Intelligence, +10 Social | Preschooler |
| Playmate | 0.02 ETH | +20 Happiness, +25 Social | Infant |
| Grandma Visit | 0.03 ETH | +15 Health, +25 Happiness | Newborn |

### Family System
- **Cooperative Care**: All parents can feed, play, and care
- **Shared Resources**: Joint token pools for expenses
- **Communication**: Family chat and coordination tools
- **Conflict Resolution**: Democratic voting on major decisions

## 🚀 Getting Started

### Prerequisites
- Ethereum wallet (MetaMask, Rainbow, etc.)
- Celo network setup
- Farcaster account
- Minimum 0.01 ETH for fees

### Installation & Deployment

```bash
# Clone the repository
git clone https://github.com/your-repo/farbaby
cd farbaby

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Fill in your private keys and RPC URLs

# Deploy to Celo
npx hardhat run scripts/deploy.js --network celo

# Verify contract (optional)
npx hardhat verify --network celo DEPLOYED_ADDRESS
```

### Environment Variables
```env
PRIVATE_KEY=your_deployer_private_key
CELO_RPC_URL=https://forno.celo.org
ETHERSCAN_API_KEY=your_api_key_for_verification
```

## 📱 Frontend Integration

### Basic Contract Interaction
```javascript
import { ethers } from 'ethers';
import FarbabyABI from './abi/FarbabyGameV1.json';

const contract = new ethers.Contract(
  FARBABY_ADDRESS,
  FarbabyABI,
  signer
);

// Register player
await contract.registerPlayer("MyNickname", "");

// Create baby with co-parents
await contract.createBaby(
  "Baby Name",
  "0510030105", // appearance string
  [coParent1Address, coParent2Address],
  { value: ethers.utils.parseEther("0.001") }
);

// Feed baby
await contract.feedBaby(
  babyId,
  "normalFood",
  { value: ethers.utils.parseEther("0.001") }
);
```

### Farcaster Frame Integration
```javascript
// Frame for quick baby care
const careFrame = {
  image: `${baseUrl}/baby/${babyId}/status`,
  buttons: [
    { text: "Feed", action: "post", target: `${baseUrl}/feed/${babyId}` },
    { text: "Play", action: "post", target: `${baseUrl}/play/${babyId}` },
    { text: "Check Health", action: "post", target: `${baseUrl}/health/${babyId}` }
  ]
};
```

## 🔧 Development

### Project Structure
```
farbaby/
├── contracts/
│   ├── FarbabyGameV1.sol
│   ├── FarbabyProxy.sol
│   └── interfaces/
├── scripts/
│   ├── deploy.js
│   ├── upgrade.js
│   └── admin.js
├── test/
│   ├── FarbabyGame.test.js
│   └── helpers/
├── frontend/
│   ├── components/
│   ├── pages/
│   └── utils/
└── docs/
```

### Running Tests
```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/FarbabyGame.test.js

# Run with coverage
npx hardhat coverage
```

### Local Development
```bash
# Start local hardhat network
npx hardhat node

# Deploy to local network
npx hardhat run scripts/deploy.js --network localhost

# Start frontend development server
cd frontend
npm run dev
```

## 🎨 Appearance System

### 10-Character Appearance String
Format: `HHEESSPPMM`
- `HH`: Hair color (01-20)
- `EE`: Eye color (01-10)
- `SS`: Skin tone (01-15)
- `PP`: Special features (01-50, rare traits)
- `MM`: Mood/Expression (01-10)

### Examples
- `0510030105`: Brown hair, blue eyes, medium skin, no special features, happy
- `1807120890`: Blonde hair, green eyes, dark skin, wings (rare), surprised

## 🏆 Leaderboards & Achievements

### Leaderboard Categories
- **Healthiest Baby Overall**
- **Most Intelligent Baby**
- **Best Cooperative Family**
- **Longest Survival Streak**
- **Most Babies Raised to Adulthood**

### Achievement System
- **First Steps**: Baby learns to walk
- **First Words**: Intelligence milestone
- **Perfect Health**: Maintain 100 health for 1 month
- **Family Harmony**: High cooperation score
- **Community Hero**: Help 10 struggling families

## 💰 Economic Model

### Revenue Streams
- Baby creation fees
- Activity microtransactions
- Premium food and items
- Adoption fees
- Family services

### Token Distribution
- 70% - Game development and maintenance
- 20% - Community rewards and events
- 10% - Emergency baby care fund

## 🛡️ Security Features

### Smart Contract Security
- OpenZeppelin upgradeable contracts
- Multi-signature requirements for upgrades
- Pausable functionality for emergencies
- Reentrancy protection on all payable functions

### Game Integrity
- Time-based validation to prevent cheating
- Community reporting system for neglect
- Automated health checks and alerts
- Transparent on-chain activity logs

## 🤝 Community Features

### Child Services System
- Community can report neglected babies
- Democratic voting on interventions
- Temporary fostering for at-risk babies
- Rehabilitation programs for bad parents

### Social Interactions
- Family chat systems
- Community forums
- Mentorship programs
- Seasonal events and competitions

## 📈 Roadmap

### Phase 1 (Current)
- ✅ Core game mechanics
- ✅ Cooperative parenting system
- ✅ Basic Farcaster integration
- 🔄 Contract deployment on Celo

### Phase 2 (Q3 2025)
- 🔲 Advanced genetics system
- 🔲 Breeding mechanics
- 🔲 Enhanced family features
- 🔲 Mobile app development

### Phase 3 (Q4 2025)
- 🔲 Cross-chain expansion
- 🔲 AI-powered baby personalities
- 🔲 Virtual reality integration
- 🔲 DAO governance system

### Phase 4 (2026)
- 🔲 Metaverse integration
- 🔲 Educational partnerships
- 🔲 Real-world baby care training
- 🔲 Global tournaments

## 📞 Support & Community

### Resources
- **Documentation**: [docs.farbaby.game](https://docs.farbaby.game)
- **Discord**: [discord.gg/farbaby](https://discord.gg/farbaby)
- **Farcaster**: [@farbaby](https://warpcast.com/farbaby)
- **Twitter**: [@FarbabyGame](https://twitter.com/FarbabyGame)

### Getting Help
1. Check the [FAQ](https://docs.farbaby.game/faq)
2. Join our Discord for community support
3. Report bugs via GitHub Issues
4. Contact team directly for urgent matters

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

Farbaby is a game with real financial costs and permanent consequences. Please:
- Only invest what you can afford to lose
- Understand that babies can permanently die
- Coordinate carefully with co-parents
- Read all terms and conditions before playing

**Remember**: This is not just a game - it's a year-long commitment to virtual life! 🍼💕

---

*Built with ❤️ by the Farbaby team for the Farcaster community*
