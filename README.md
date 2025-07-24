# VaultCoin Protocol

![Stacks](https://img.shields.io/badge/Stacks-Bitcoin_Layer-orange.svg)
![Clarity](https://img.shields.io/badge/Clarity-3.1-blue.svg)
![License](https://img.shields.io/badge/license-ISC-green.svg)

## Overview

VaultCoin Protocol is a revolutionary DeFi infrastructure that transforms Bitcoin holdings into productive liquidity through sophisticated collateralized debt positions (CDPs). Built on the Stacks blockchain, it enables users to leverage their BTC holdings to mint USD-pegged stablecoins while maintaining exposure to Bitcoin's long-term value appreciation.

The protocol bridges traditional Bitcoin holding strategies with modern DeFi yield generation, enabling capital efficiency without sacrificing the security of Bitcoin-denominated assets.

## 🚀 Key Features

### Core Functionality

- **Bitcoin-Collateralized Stablecoins**: Mint VaultCoins using BTC as collateral
- **Native Bitcoin Integration**: Built on Stacks for seamless Bitcoin interoperability
- **Overcollateralized System**: 150% minimum collateralization ratio ensures stability
- **Interest Accrual**: Dynamic interest rates on borrowed positions
- **Liquidation Protection**: Automated liquidation system maintains protocol solvency
- **Price Oracle Integration**: Real-time BTC/USD price feeds with staleness validation

### Advanced Features

- **Position Management**: Add/withdraw collateral, repay debt, close positions
- **Emergency Controls**: Protocol pause mechanism for security
- **Liquidation Incentives**: 10% liquidation bonus for liquidators
- **Compound Interest**: Block-based interest accrual system
- **Multi-Position Support**: Users can expand existing positions

## 📊 Protocol Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| **Minimum Collateral Ratio** | 150% | Required overcollateralization |
| **Liquidation Threshold** | 120% | Point at which positions become liquidatable |
| **Liquidation Penalty** | 10% | Bonus awarded to liquidators |
| **Minimum Loan Amount** | 100 VaultCoins | Smallest borrowable amount |
| **Interest Rate** | ~10% APR | Block-based compound interest |
| **Price Feed Expiry** | 24 hours | Maximum price staleness allowed |

## 🏗️ Smart Contract Architecture

### Core Components

#### State Management

- **Global Variables**: Protocol metrics, ownership, pause state
- **User Positions**: Collateral, debt, and update tracking per user
- **Price Oracle**: BTC/USD price feeds with timestamp validation
- **Interest System**: Block-based compound interest accrual

#### Key Functions

##### Administrative Functions

```clarity
(set-protocol-owner (new-owner principal))    ;; Transfer ownership
(pause-protocol (paused bool))                ;; Emergency pause
(update-btc-price (price uint) (timestamp uint)) ;; Oracle updates
```

##### Core User Functions

```clarity
(create-position (btc-amount uint) (stable-amount uint)) ;; Open/expand position
(add-collateral (btc-amount uint))             ;; Add collateral
(repay-debt (amount uint))                     ;; Repay VaultCoins
(withdraw-collateral (btc-amount uint))        ;; Withdraw excess collateral
(liquidate-position (user principal))         ;; Liquidate undercollateralized position
```

##### Read-Only Functions

```clarity
(get-position (user principal))                ;; Position details
(get-collateralization-ratio (user principal)) ;; Current ratio
(get-protocol-stats)                          ;; Global metrics
(get-current-price)                           ;; BTC price with validation
```

## 🛠️ Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) (Latest version)
- [Node.js](https://nodejs.org/) (v18+)
- [TypeScript](https://www.typescriptlang.org/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/adefola-yanju/vault-coin.git
   cd vault-coin
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify Clarinet installation**

   ```bash
   clarinet --version
   ```

### Project Structure

```
vault-coin/
├── contracts/
│   └── vault-coin.clar          # Main protocol contract
├── tests/
│   └── vault-coin.test.ts       # Test suite
├── settings/
│   ├── Devnet.toml             # Development network config
│   ├── Testnet.toml            # Testnet configuration
│   └── Mainnet.toml            # Mainnet configuration
├── Clarinet.toml               # Project configuration
├── package.json                # Node.js dependencies
└── vitest.config.js           # Test configuration
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for continuous testing
npm run test:watch

# Clarinet contract validation
clarinet check
```

### Test Environment

- **Framework**: Vitest with Clarinet SDK
- **Environment**: `vitest-environment-clarinet`
- **Coverage**: Built-in coverage reporting
- **Cost Analysis**: Transaction cost estimation

### Example Test Structure

```typescript
import { describe, expect, it } from "vitest";

describe("VaultCoin Protocol", () => {
  it("should create position with valid collateral", () => {
    // Test implementation
  });
  
  it("should prevent undercollateralized borrowing", () => {
    // Test implementation
  });
});
```

## 📈 Usage Examples

### Creating a Position

```clarity
;; User deposits 1 BTC (100,000,000 satoshis) and borrows 30,000 VaultCoins
;; Assumes BTC price of $50,000 USD
(contract-call? .vault-coin create-position u100000000 u3000000000000)
```

### Adding Collateral

```clarity
;; Add 0.5 BTC to existing position
(contract-call? .vault-coin add-collateral u50000000)
```

### Repaying Debt

```clarity
;; Repay 10,000 VaultCoins
(contract-call? .vault-coin repay-debt u1000000000000)
```

### Checking Position Health

```clarity
;; Get current collateralization ratio
(contract-call? .vault-coin get-collateralization-ratio tx-sender)
```

## 🔒 Security Features

### Risk Management

- **Overcollateralization**: Minimum 150% collateral ratio
- **Liquidation System**: Automated position liquidation at 120% ratio
- **Price Feed Validation**: 24-hour expiry on price data
- **Interest Accrual**: Compound interest prevents debt growth manipulation

### Access Controls

- **Owner-only Functions**: Protocol administration restricted
- **Emergency Pause**: Immediate protocol suspension capability
- **Self-liquidation Prevention**: Users cannot liquidate their own positions

### Economic Security

- **Liquidation Incentives**: 10% bonus encourages timely liquidations
- **Stability Fees**: Protocol revenue from interest and penalties
- **Global Debt Tracking**: Comprehensive system-wide metrics

## 🌐 Deployment

### Network Configurations

#### Devnet (Development)

```bash
clarinet console
```

#### Testnet

```bash
clarinet deploy --testnet
```

#### Mainnet

```bash
clarinet deploy --mainnet
```

### Environment Variables

Configure price oracle endpoints and administrative keys in respective network settings files.

## 📚 Documentation

### Protocol Mechanics

- **Collateralization**: Users must maintain >150% collateral-to-debt ratio
- **Interest**: Compounds per block at ~10% APR
- **Liquidation**: Triggered automatically when positions fall below 120% ratio
- **Price Oracle**: Requires fresh BTC/USD prices (< 24 hours old)

### Error Codes

| Code | Error | Description |
|------|--------|-------------|
| u1000 | ERR-NOT-AUTHORIZED | Unauthorized access attempt |
| u1001 | ERR-INSUFFICIENT-COLLATERAL | Inadequate collateral for operation |
| u1002 | ERR-POSITION-NOT-FOUND | No position exists for user |
| u1003 | ERR-UNDERCOLLATERALIZED | Position below safety threshold |
| u1004 | ERR-MINIMUM-LOAN-REQUIRED | Loan amount below minimum |
| u1005 | ERR-INSUFFICIENT-DEBT | Repayment exceeds debt |
| u1006 | ERR-PRICE-EXPIRED | Stale price data |
| u1007 | ERR-PROTOCOL-PAUSED | Protocol emergency pause active |
| u1008 | ERR-INVALID-AMOUNT | Invalid amount parameter |
| u1009 | ERR-NO-PRICE-DATA | No price data available |

## 🤝 Contributing

We welcome contributions to the VaultCoin Protocol! Please follow these guidelines:

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Ensure all tests pass (`npm test`)
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Include comprehensive test coverage
- Document new functions and parameters
- Use descriptive variable names
- Add inline comments for complex logic

### Testing Requirements

- All new features must include tests
- Maintain >90% test coverage
- Include both positive and negative test cases
- Test edge cases and error conditions

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **GitHub**: [adefola-yanju/vault-coin](https://github.com/adefola-yanju/vault-coin)
- **Stacks Documentation**: [docs.stacks.co](https://docs.stacks.co)
- **Clarity Language**: [clarity.stacks.org](https://clarity.stacks.org)
- **Clarinet Tools**: [github.com/hirosystems/clarinet](https://github.com/hirosystems/clarinet)
