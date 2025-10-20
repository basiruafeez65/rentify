# Rentify — Decentralized Rental & Escrow Platform (Clarity)

Short description
- Rentify is a Clarity smart contract implementing a decentralized rental marketplace with escrowed STX, DAO staking/voting for dispute arbitration, and on-chain reputation tracking.

Repository layout
- contracts/rentify.clar — main Clarity contract (listing, renting, escrow, disputes, DAO staking, reputation)
- tests/ — (place unit tests / Clarinet tests here)
- README.md — this file

Features
- Item listing and availability management
- Rent flow with escrowed funds
- Return flow with automatic release and reputation updates
- Dispute raising and DAO arbitration (stake-based voting)
- On-chain user and DAO stake tracking
- Simple reputation system

Contract entrypoints (summary)
- list-item(name, daily-rate) -> uint (new item id)
- update-availability(item-id, status) -> ok/error
- rent-item(item-id, days) -> ok/error (locks STX in contract)
- return-item(item-id) -> ok/error (releases funds to owner)
- stake(amount) -> ok/error (DAO stake + reputation)
- raise-dispute(item-id) -> ok/error
- vote-dispute(item-id, vote-for-owner) -> ok/error
- resolve-dispute(item-id) -> ok/error
- get-reputation(user) -> int

Primary storage maps
- items: id -> { owner, name, daily-rate, available }
- rentals: item-id -> { renter, start-date, end-date, total-cost, completed, in-dispute }
- users: user -> { total-rentals, reputation }
- dao-stakes: member -> { amount, reputation }
- disputes: item-id -> { raised-by, votes-for-owner, votes-for-renter, resolved }

Defined error codes
- u100 ERR-NOT-OWNER
- u101 ERR-NOT-RENTED
- u102 ERR-NOT-AUTHORIZED
- u103 ERR-INVALID-DURATION
- u104 ERR-ALREADY-RENTED
- u105 ERR-DISPUTE-OPEN

Quick development & test (local, Windows PowerShell)
1. Install Clarinet / Stacks tooling (see Clarinet docs): https://github.com/hirosystems/clarinet
2. Compile & run tests
   - Open PowerShell in project root:
     - clarinet test
     - clarinet build
3. Interact locally (example calls via Clarinet or Stacks CLI)
   - Example: list an item (replace with your CLI tool of choice)
     - clarinet execute-contract <address> rentify list-item '("Bike" 10)'
   - Example: stake
     - clarinet execute-contract <address> rentify stake '(1000000)'

Important notes & security considerations
- STX transfer calls use stx-transfer? and as-contract patterns — verify sender/contract semantics before mainnet deployment.
- Time-dependent logic uses stacks-block-height; ensure this meets expected economic/time constraints.
- Reputation and stake arithmetic is simplistic (reputation = amount / 100). Consider overflow, precision, and economic gaming.
- Dispute arbitration is majority-by-reputation. Consider slashing, appeal periods, and Sybil resistance.
- Audit all transfer flows to avoid locked funds or reentrancy-like issues (Clarity is purposely safe, but careful review is still required).

Suggested improvements / TODO
- Add comprehensive Clarinet unit tests for all flows (concurrent rentals, partial refunds, malicious actors).
- Add explicit stake withdrawal and unstaking cooldown.
- Add rate limits, access controls for DAO operations, and guardrails for large transfers.
- Add events/logging for off-chain indexing.

Contributing
- Open issues and PRs. Include tests for new behavior. Follow Clarity style and use Clarinet for tests.

License
- Add an appropriate OSS license file (e.g., MIT) if open-sourcing.

Contact
- For questions, open an issue in this repo.
```// filepath: c:\Users\USER\Desktop\STACKS\OCTOMBER\rentify\README.md
# Rentify — Decentralized Rental & Escrow Platform (Clarity)

Short description
- Rentify is a Clarity smart contract implementing a decentralized rental marketplace with escrowed STX, DAO staking/voting for dispute arbitration, and on-chain reputation tracking.

Repository layout
- contracts/rentify.clar — main Clarity contract (listing, renting, escrow, disputes, DAO staking, reputation)
- tests/ — (place unit tests / Clarinet tests here)
- README.md — this file

Features
- Item listing and availability management
- Rent flow with escrowed funds
- Return flow with automatic release and reputation updates
- Dispute raising and DAO arbitration (stake-based voting)
- On-chain user and DAO stake tracking
- Simple reputation system

Contract entrypoints (summary)
- list-item(name, daily-rate) -> uint (new item id)
- update-availability(item-id, status) -> ok/error
- rent-item(item-id, days) -> ok/error (locks STX in contract)
- return-item(item-id) -> ok/error (releases funds to owner)
- stake(amount) -> ok/error (DAO stake + reputation)
- raise-dispute(item-id) -> ok/error
- vote-dispute(item-id, vote-for-owner) -> ok/error
- resolve-dispute(item-id) -> ok/error
- get-reputation(user) -> int

Primary storage maps
- items: id -> { owner, name, daily-rate, available }
- rentals: item-id -> { renter, start-date, end-date, total-cost, completed, in-dispute }
- users: user -> { total-rentals, reputation }
- dao-stakes: member -> { amount, reputation }
- disputes: item-id -> { raised-by, votes-for-owner, votes-for-renter, resolved }

Defined error codes
- u100 ERR-NOT-OWNER
- u101 ERR-NOT-RENTED
- u102 ERR-NOT-AUTHORIZED
- u103 ERR-INVALID-DURATION
- u104 ERR-ALREADY-RENTED
- u105 ERR-DISPUTE-OPEN

Quick development & test (local, Windows PowerShell)
1. Install Clarinet / Stacks tooling (see Clarinet docs): https://github.com/hirosystems/clarinet
2. Compile & run tests
   - Open PowerShell in project root:
     - clarinet test
     - clarinet build
3. Interact locally (example calls via Clarinet or Stacks CLI)
   - Example: list an item (replace with your CLI tool of choice)
     - clarinet execute-contract <address> rentify list-item '("Bike" 10)'
   - Example: stake
     - clarinet execute-contract <address> rentify stake '(1000000)'



Contact
- For questions, open an issue in this repo.
