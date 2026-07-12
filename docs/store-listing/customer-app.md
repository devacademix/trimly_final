# Play Store listing — Trimly (customer app)

Draft copy. Edit freely — nothing here is final, it's a starting point so the
listing form isn't blank when you sit down to submit.

- **App name**: Trimly
- **Package name**: `com.trimly.customer`
- **Category**: Lifestyle (alt: Beauty)
- **Short description** (max 80 chars):
  > Book salon & grooming appointments near you, in a few taps.
- **Full description** (max 4000 chars):
  > Trimly makes booking a salon or grooming appointment simple. Browse
  > salons near you, check real-time availability, pick your stylist and
  > service, and book instantly — no phone calls required.
  >
  > • Discover salons near you with real prices and reviews
  > • Book appointments in real time — no waiting for confirmation calls
  > • Pay securely in-app or at the salon
  > • Get reminders so you never miss an appointment
  > • Track your booking history and reorder your favorite services
  > • Chat directly with your salon about your appointment
  >
  > Whether it's a haircut, a spa day, or grooming before a big event,
  > Trimly gets you booked in minutes.
- **Contact email**: [support email]
- **Privacy policy URL**: `<admin-domain>/privacy`

## Content rating questionnaire — likely answers
- Violence / sexual content / drugs: None
- User-generated content: Yes (chat with salons; reviews if/when shipped) —
  disclose this, since it affects the rating and requires a moderation/report
  mechanism per store policy.
- In-app purchases / payments: Yes (Razorpay-processed bookings)
- Location access: Yes (used to find nearby salons)
- Target audience: 18+ recommended, given account creation + payments

## Screenshots needed (phone, min 2, up to 8)
1. Salon discovery / home screen
2. Salon detail + booking flow
3. Payment / checkout
4. Booking confirmation / upcoming bookings
5. Chat with salon (if included)

## Data safety section (Play Console)
Declare each category actually collected — cross-check against
`docs/PRODUCTION_CHECKLIST.md` §1 and the app's real network calls before
submitting, since Play Console checks this against the app's actual behavior:
- Personal info: name, phone number, email
- Location: approximate/precise (for salon discovery)
- Financial info: payment history (not card numbers — Razorpay handles those)
- App activity: booking history, app interactions
- Device/other IDs: for push notifications (FCM token)
