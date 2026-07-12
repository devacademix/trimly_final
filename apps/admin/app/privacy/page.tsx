import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Privacy Policy',
  robots: { index: true, follow: true },
};

const h2 = 'mt-8 text-lg font-semibold text-slate-900 dark:text-slate-50';
const p = 'mt-3 text-sm leading-relaxed';
const ul = 'mt-3 list-disc space-y-1.5 pl-5 text-sm leading-relaxed';

export default function PrivacyPolicyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-slate-800 dark:text-slate-200">
      <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-50">Privacy Policy</h1>
      <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">Last updated: [DATE]</p>

      <p className={`${p} rounded-md bg-amber-50 px-3 py-2 text-amber-800 dark:bg-amber-950 dark:text-amber-400`}>
        <strong>
          This is a starting template, not a finished legal document. Replace every [bracketed]
          placeholder and have it reviewed by a lawyer before publishing it live or submitting
          either app to an app store.
        </strong>
      </p>

      <p className={p}>
        [Company legal name] (&quot;Trimly&quot;, &quot;we&quot;, &quot;us&quot;) operates the Trimly
        customer and salon mobile applications and the associated booking platform. This policy
        explains what information we collect, how we use it, and the choices you have.
      </p>

      <h2 className={h2}>Information we collect</h2>
      <ul className={ul}>
        <li><strong>Account information</strong> — name, phone number, email address.</li>
        <li>
          <strong>Location</strong> — approximate or precise location, when you allow it, used to
          show nearby salons.
        </li>
        <li>
          <strong>Booking &amp; payment activity</strong> — appointments, service history, and
          payment status. Card and UPI details are collected and processed directly by our
          payment processor (Razorpay) — we do not store your card number or bank credentials.
        </li>
        <li>
          <strong>Device &amp; usage data</strong> — device identifiers, app version, and crash/
          diagnostic data, used to keep the app working and secure.
        </li>
        <li>
          <strong>Push notification tokens</strong> — used to send booking updates and reminders
          via Firebase Cloud Messaging.
        </li>
      </ul>

      <h2 className={h2}>How we use this information</h2>
      <ul className={ul}>
        <li>To create and manage your account and bookings.</li>
        <li>To process payments and settlements with salons.</li>
        <li>To send booking confirmations, reminders, and support messages (SMS/email/push).</li>
        <li>To show you nearby salons and relevant search results.</li>
        <li>To detect, prevent, and investigate fraud, abuse, or security incidents.</li>
        <li>To improve the app through aggregated, non-identifying analytics.</li>
      </ul>

      <h2 className={h2}>Who we share it with</h2>
      <p className={p}>
        We share data with the service providers that make the app work — payment processing
        (Razorpay), push notifications (Firebase/Google), SMS/OTP delivery, cloud hosting and
        storage, and, where relevant, the salon you book with (your name, phone number, and
        appointment details, so they can serve you). We do not sell your personal data.
      </p>

      <h2 className={h2}>Data retention</h2>
      <p className={p}>
        We retain account and booking data for as long as your account is active and for
        [retention period, e.g. 3 years] afterward for legal, tax, and dispute-resolution
        purposes, after which it is deleted or anonymized.
      </p>

      <h2 className={h2}>Your choices</h2>
      <ul className={ul}>
        <li>You can update your profile information from within the app.</li>
        <li>You can disable location and notification permissions from your device settings.</li>
        <li>
          You can request access to, correction of, or deletion of your personal data by
          contacting us at [support email].
        </li>
      </ul>

      <h2 className={h2}>Children</h2>
      <p className={p}>Trimly is not directed at children under 18 and we do not knowingly collect their data.</p>

      <h2 className={h2}>Changes to this policy</h2>
      <p className={p}>
        We may update this policy from time to time. Material changes will be notified via the
        app or by email.
      </p>

      <h2 className={h2}>Contact us</h2>
      <p className={p}>
        [Company legal name], [address].
        <br />
        Email: [support email]
      </p>
    </div>
  );
}
