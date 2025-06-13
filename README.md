# SkillForge Protocol

## Overview

SkillForge is a revolutionary decentralized learning and certification protocol built on the Stacks blockchain. It enables instructors to create courses, students to enroll with stake-based commitments, and issues verifiable on-chain certifications upon completion.

## Key Features

### 🎓 **Decentralized Course Creation**
- Instructors can create courses with custom pricing and stake requirements
- Support for multiple categories: Programming, Design, Marketing, Finance, Business, Data Science, Blockchain, AI/ML
- Four difficulty levels: Beginner, Intermediate, Advanced, Expert
- Flexible duration settings (1 day to 1 year)

### 💰 **Stake-Based Learning Commitment**
- Students stake tokens alongside course fees to ensure commitment
- Stake is returned upon successful completion and certification
- Prevents course abandonment and ensures serious learners

### 🏆 **On-Chain Certifications**
- Verifiable certifications stored permanently on the blockchain
- Immutable proof of skill completion
- Certificate hash system for additional verification
- Minimum 80% completion threshold required

### 📊 **Comprehensive Analytics**
- Course completion rates and statistics
- Platform-wide metrics and treasury management
- Individual progress tracking
- Instructor performance insights

## Technical Architecture

### Smart Contract Functions

#### Course Management
- `create-course`: Create new learning courses
- `deactivate-course`: Deactivate courses (instructor only)
- `get-course`: Retrieve course information
- `get-course-stats`: Get course analytics

#### Enrollment System
- `enroll-in-course`: Enroll in courses with payment and stake
- `update-progress`: Track learning progress
- `get-student-enrollment`: Check enrollment status

#### Certification System
- `issue-certification`: Issue verifiable certificates
- `get-certification`: Retrieve certification records
- `is-student-certified`: Check certification status

### Data Structures

#### Course Schema
```
{
  instructor: principal,
  title: string-utf8(100),
  description: string-utf8(500),
  category: string-utf8(20),
  difficulty: string-utf8(10),
  price: uint,
  stake-amount: uint,
  duration: uint (seconds),
  is-active: bool,
  total-enrolled: uint,
  total-certified: uint,
  created-at: uint
}
```

#### Enrollment Schema
```
{
  student: principal,
  course-id: uint,
  enrolled-at: uint,
  expires-at: uint,
  progress: uint (0-100),
  is-completed: bool,
  is-certified: bool,
  stake-locked: uint
}
```

## Economic Model

### Fee Structure
- **Platform Fee**: 5% of course price
- **Instructor Revenue**: 95% of course price
- **Stake Mechanism**: Refundable commitment deposit
- **Minimum Price**: 1 STX
- **Maximum Price**: 1,000,000 STX

### Incentive Alignment
- Students commit stake to ensure completion
- Instructors earn revenue from successful enrollments
- Platform benefits from transaction fees
- Quality courses attract more students

## Security Features

### Input Validation
- Comprehensive text length validation
- Price and duration bounds checking
- Category and difficulty validation
- Progress bounds verification

### Access Control
- Instructor-only course management
- Student enrollment verification
- Certification eligibility checks
- Stake lock mechanisms

### Error Handling
- 16 distinct error codes for precise debugging
- Graceful failure modes
- Transaction rollback protection
- Input sanitization

## Use Cases

### For Instructors
- Monetize expertise through course creation
- Build reputation with verifiable student outcomes
- Access global student market
- Earn passive income from quality content

### For Students
- Access high-quality, commitment-based learning
- Earn verifiable blockchain credentials
- Benefit from stake-based motivation system
- Build portfolio of certified skills

### For Organizations
- Verify employee skills through blockchain certificates
- Create internal training programs
- Reduce hiring risks with verified qualifications
- Build talent pipeline with certified professionals

## Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Clarinet development environment
- Basic understanding of Clarity smart contracts

### Deployment
1. Clone the repository
2. Run `clarinet check` to verify contract syntax
3. Deploy to testnet for testing
4. Deploy to mainnet for production use

### Example Usage

```clarity
;; Create a programming course
(contract-call? .skillforge create-course 
  u"Advanced Smart Contract Development" 
  u"Learn to build secure and efficient smart contracts on Stacks blockchain with hands-on projects and real-world examples."
  u"Programming" 
  u"Advanced" 
  u5000000   ;; 5 STX price
  u2000000   ;; 2 STX stake
  u2592000   ;; 30 days duration
)

;; Enroll in a course
(contract-call? .skillforge enroll-in-course u1)

;; Update progress
(contract-call? .skillforge update-progress u1 u85)

;; Issue certification
(contract-call? .skillforge issue-certification u1 u"abc123...hash")
```

## Future Enhancements

- NFT-based certificates
- Multi-token payment support
- Decentralized course content storage
- Peer-to-peer learning features
- Advanced analytics dashboard
- Mobile application integration

## Contributing

We welcome contributions to improve SkillForge Protocol. Please follow standard development practices and ensure all tests pass before submitting pull requests.