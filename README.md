# Smart Public Library Study Room Booking System

A comprehensive blockchain-based system for managing library study room reservations, occupancy monitoring, equipment checkout, noise complaints, and cleaning schedules.

## System Overview

This system consists of five interconnected smart contracts that work together to provide a complete library study room management solution:

### 1. Room Reservation Contract (`room-reservation.clar`)
- Manages hourly study room bookings
- Handles reservation cancellations
- Tracks booking history and availability
- Supports multiple room types and capacities

### 2. Occupancy Monitoring Contract (`occupancy-monitoring.clar`)
- Tracks real-time room usage
- Enforces capacity limits
- Monitors check-in/check-out times
- Provides occupancy analytics

### 3. Equipment Checkout Contract (`equipment-checkout.clar`)
- Manages projector and whiteboard marker loans
- Tracks equipment availability and condition
- Handles equipment returns and damage reports
- Maintains equipment usage history

### 4. Noise Complaint Contract (`noise-complaint.clar`)
- Processes disturbance reports
- Manages quiet zone enforcement
- Tracks complaint patterns
- Implements warning and penalty systems

### 5. Cleaning Scheduling Contract (`cleaning-scheduling.clar`)
- Coordinates daily room sanitization
- Manages maintenance schedules
- Tracks cleaning completion status
- Handles emergency cleaning requests

## Features

### Room Reservation System
- **Hourly Bookings**: Reserve rooms for 1-8 hour blocks
- **Flexible Cancellation**: Cancel reservations up to 2 hours before start time
- **Room Types**: Support for individual study rooms, group rooms, and presentation rooms
- **Capacity Management**: Automatic capacity enforcement based on room type

### Occupancy Monitoring
- **Real-time Tracking**: Monitor current occupancy levels
- **Capacity Enforcement**: Prevent overcrowding with automatic limits
- **Usage Analytics**: Track peak hours and room utilization
- **Check-in System**: Verify actual room usage vs. reservations

### Equipment Management
- **Digital Checkout**: Borrow projectors and whiteboard markers
- **Availability Tracking**: Real-time equipment status
- **Damage Reporting**: Report and track equipment condition
- **Usage History**: Maintain complete equipment loan records

### Noise Management
- **Complaint System**: Report noise disturbances with severity levels
- **Quiet Zone Enforcement**: Special rules for designated quiet areas
- **Pattern Recognition**: Track repeat offenders and problem areas
- **Automated Warnings**: Progressive penalty system

### Cleaning Coordination
- **Daily Schedules**: Automated cleaning task assignment
- **Completion Tracking**: Verify cleaning task completion
- **Emergency Requests**: Handle urgent cleaning needs
- **Maintenance Logs**: Complete cleaning and maintenance history

## Data Structures

### Room Types
- **Individual Study**: 1-2 person capacity, quiet zones
- **Group Study**: 3-8 person capacity, collaborative spaces
- **Presentation**: 8-20 person capacity, equipped with projectors

### Equipment Types
- **Projectors**: Limited quantity, requires room reservation
- **Whiteboard Markers**: Consumable items, tracked by set
- **Cleaning Supplies**: Managed by cleaning staff

### Time Management
- **Booking Slots**: Hourly increments from 8 AM to 10 PM
- **Advance Booking**: Up to 7 days in advance
- **Cancellation Window**: Minimum 2 hours before start time

## Error Handling

The system implements comprehensive error handling for:
- Invalid room numbers or types
- Booking conflicts and capacity violations
- Equipment unavailability
- Unauthorized access attempts
- Invalid time ranges and scheduling conflicts

## Security Features

- **User Authentication**: Verified library card holders only
- **Role-based Access**: Different permissions for patrons, staff, and administrators
- **Audit Trail**: Complete transaction history for all operations
- **Data Validation**: Strict input validation and sanitization

## Installation and Setup

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute the test suite
5. Deploy contracts using `clarinet deploy`

## Testing

The system includes comprehensive tests covering:
- All contract functions and edge cases
- Integration scenarios between contracts
- Error handling and validation
- Performance and gas optimization

## Usage Examples

### Making a Room Reservation
\`\`\`clarity
(contract-call? .room-reservation book-room u1 u1234567890 u2)
\`\`\`

### Checking Equipment Availability
\`\`\`clarity
(contract-call? .equipment-checkout check-availability "projector")
\`\`\`

### Reporting a Noise Complaint
\`\`\`clarity
(contract-call? .noise-complaint file-complaint u1 u3 "Loud conversation in quiet zone")
\`\`\`

## Contract Addresses

After deployment, update this section with the actual contract addresses on the Stacks blockchain.

## Contributing

Please read the PR-DETAILS.md file for information about contributing to this project.

## License

This project is licensed under the MIT License.
