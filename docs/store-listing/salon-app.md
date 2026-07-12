# Play Store listing — Trimly for Business (salon app)

Draft copy. Edit freely — nothing here is final, it's a starting point so the
listing form isn't blank when you sit down to submit.

- **App name**: Trimly for Business
- **Package name**: `com.trimly.salon`
- **Category**: Business (alt: Productivity)
- **Short description** (max 80 chars):
  > Manage your salon's bookings, staff, and customers from your phone.
- **Full description** (max 4000 chars):
  > Trimly for Business is the salon owner's companion to the Trimly booking
  > platform. Manage incoming appointments, your staff roster, inventory,
  > and customer relationships — all from one app.
  >
  > • See and manage bookings in real time as customers book you
  > • Confirm, reschedule, or complete appointments on the go
  > • Manage staff schedules and assignments
  > • Track inventory and stock levels
  > • View your wallet balance and settlement history
  > • Chat directly with customers about their bookings
  > • Get instant push notifications for new bookings
  >
  > Built for independent salons and grooming businesses that want to run
  > their booking operations without a front desk.
- **Contact email**: [support email]
- **Privacy policy URL**: `<admin-domain>/privacy`

## Content rating questionnaire — likely answers
- Violence / sexual content / drugs: None
- User-generated content: Yes (chat with customers) — disclose this, since
  it affects the rating and requires a moderation/report mechanism per store
  policy.
- In-app purchases / payments: Indirect (views settlement/wallet data;
  confirm whether any in-app purchase flow exists before submitting)
- Location access: Confirm whether the salon app requests location (e.g. for
  salon address setup) before answering this in Play Console
- Target audience: 18+ (business/professional use)

## Screenshots needed (phone, min 2, up to 8)
1. Bookings dashboard
2. Booking detail / confirm-reschedule-complete flow
3. Staff roster
4. Inventory management
5. Wallet / settlements

## Data safety section (Play Console)
Declare each category actually collected — cross-check against
`docs/PRODUCTION_CHECKLIST.md` §1 and the app's real network calls before
submitting, since Play Console checks this against the app's actual behavior:
- Personal info: name, phone number, email (salon owner/staff account)
- Financial info: settlement/wallet balance and transaction history
- App activity: booking management actions
- Device/other IDs: for push notifications (FCM token)
