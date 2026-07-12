import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Terms of Service',
  robots: { index: true, follow: true },
};

const h2 = 'mt-8 text-lg font-semibold text-slate-900 dark:text-slate-50';
const p = 'mt-3 text-sm leading-relaxed';

export default function TermsOfServicePage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-slate-800 dark:text-slate-200">
      <h1 className="text-2xl font-semibold text-slate-900 dark:text-slate-50">Terms of Service</h1>
      <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">Last updated: [DATE]</p>

      <p className={`${p} rounded-md bg-amber-50 px-3 py-2 text-amber-800 dark:bg-amber-950 dark:text-amber-400`}>
        <strong>
          This is a starting template, not a finished legal document. Replace every [bracketed]
          placeholder and have it reviewed by a lawyer before publishing it live or submitting
          either app to an app store.
        </strong>
      </p>

      <p className={p}>
        These terms govern your use of the Trimly customer and salon applications, operated by
        [Company legal name] (&quot;Trimly&quot;, &quot;we&quot;, &quot;us&quot;). By creating an account or using
        the app, you agree to these terms.
      </p>

      <h2 className={h2}>The service</h2>
      <p className={p}>
        Trimly is a booking platform that connects customers with independent salons and
        grooming businesses. Trimly is not itself a salon and is not a party to the service
        agreement between a customer and a salon — we provide the booking, payment, and
        communication tools that connect them.
      </p>

      <h2 className={h2}>Accounts</h2>
      <p className={p}>
        You must provide accurate information when creating an account and are responsible for
        keeping your login credentials secure. You must be at least 18 years old to create an
        account.
      </p>

      <h2 className={h2}>Bookings, cancellations &amp; refunds</h2>
      <p className={p}>
        Booking, cancellation, and refund terms (including any cancellation window or fee) are
        set by [each salon / Trimly&apos;s cancellation policy — clarify which] and shown at the
        time of booking. [Describe the actual cancellation/refund policy here.]
      </p>

      <h2 className={h2}>Payments</h2>
      <p className={p}>
        Payments are processed by Razorpay. By making a payment through the app you agree to
        Razorpay&apos;s terms in addition to these. Trimly may charge a service or commission
        fee, disclosed at checkout.
      </p>

      <h2 className={h2}>Salon accounts</h2>
      <p className={p}>
        Salons using the Trimly for Business app are responsible for the accuracy of their
        listing, service pricing, staff scheduling, and for honoring bookings accepted through
        the platform. Trimly may suspend a salon account for fraudulent activity, repeated
        cancellations, or violation of these terms.
      </p>

      <h2 className={h2}>Prohibited use</h2>
      <p className={p}>
        You agree not to misuse the platform — including fraudulent bookings, harassment of
        other users, or attempting to circumvent payments made through the app.
      </p>

      <h2 className={h2}>Disclaimer &amp; limitation of liability</h2>
      <p className={p}>
        The app is provided &quot;as is&quot;. Trimly is not liable for the quality of services
        provided by salons. [Add jurisdiction-appropriate liability limitation language — consult
        a lawyer.]
      </p>

      <h2 className={h2}>Termination</h2>
      <p className={p}>
        We may suspend or terminate your account for violation of these terms. You may delete
        your account at any time by contacting [support email].
      </p>

      <h2 className={h2}>Governing law</h2>
      <p className={p}>These terms are governed by the laws of [jurisdiction].</p>

      <h2 className={h2}>Contact us</h2>
      <p className={p}>
        [Company legal name], [address].
        <br />
        Email: [support email]
      </p>
    </div>
  );
}
