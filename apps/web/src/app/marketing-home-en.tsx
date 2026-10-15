import Image from "next/image";
import Link from "next/link";
import { LocaleSwitcher } from "./locale-switcher";

const features = [
  [
    "AI-assisted visit debrief",
    "Turn a voice or written field note into a transcript and an editable summary draft. A person reviews it before it becomes shared customer memory.",
  ],
  [
    "Business-card capture",
    "Scan a business card into draft contact details, review the recognized fields, then choose what to save.",
  ],
  [
    "Offline field work",
    "Keep visit and debrief drafts on the device while offline; they can sync when connectivity returns.",
  ],
  [
    "Field Mode reminders",
    "Start visible Field Mode to receive a nearby-customer reminder. Location is used for this feature while it is active and is not stored as a user location; reminders are not promised after the app is force-closed.",
  ],
  [
    "Team follow-through",
    "Keep visits, tasks, opportunities, order drafts, and approved reports connected to a customer timeline, with workspace and role-based access.",
  ],
  [
    "Document review",
    "Uploaded documents go through malware scanning before they are made available in the workspace.",
  ],
];

const faqs = [
  [
    "Does AI publish notes automatically?",
    "No. A generated summary starts as a draft. A user must review and approve it before it becomes shared customer memory.",
  ],
  [
    "Can I work without a connection?",
    "Mobile visit and debrief drafts can be queued on the device and synchronized when connectivity returns. Review the sync status before relying on a draft on another device.",
  ],
  [
    "Does KartVizyon continuously track my location?",
    "Location is used after you request nearby customers or while you explicitly run visible Field Mode. Field Mode can read location while active, shows system indicators, and stops automatically; location is not stored as your user location. The app does not promise notifications while fully terminated.",
  ],
  [
    "What does KartVizyon replace?",
    "It focuses on field-sales customer context and visit follow-up. It is not an accounting, inventory, e-invoicing, or route-optimization system.",
  ],
];

const appStoreUrl = "https://apps.apple.com/app/id6797552440";
const playStoreUrl =
  "https://play.google.com/store/apps/details?id=app.kartvizyon.mobile";

export function MarketingHomeEnglish() {
  return (
    <main className="marketing-shell" lang="en">
      <header className="marketing-nav">
        <Link className="marketing-brand" href="/" aria-label="KartVizyon home">
          <Image
            src="/brand/logo-mark.png"
            alt=""
            width={36}
            height={36}
            priority
          />
          <strong>KartVizyon</strong>
        </Link>
        <nav aria-label="Main navigation">
          <a href="#workflow">Workflow</a>
          <a href="#features">Features</a>
          <a href="#trust">Trust</a>
          <a href="#pricing">Pricing</a>
          <a href="#download">Get the app</a>
        </nav>
        <div className="marketing-actions">
          <LocaleSwitcher locale="en" />
          <a
            className="marketing-login"
            href="https://app.kartvizyon.app/login"
          >
            Sign in
          </a>
          <a
            className="marketing-cta small"
            href="mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20demo%20request"
          >
            Request a demo
          </a>
        </div>
      </header>

      <section className="marketing-hero">
        <div className="marketing-hero-copy">
          <span className="marketing-kicker">
            FIELDWORK IN · FOLLOW-THROUGH OUT
          </span>
          <h1>
            Keep the customer promise
            <em> from getting lost.</em>
          </h1>
          <p>
            KartVizyon brings visit preparation, field notes, follow-up tasks,
            and human-approved customer memory into one workspace.
          </p>
          <div className="marketing-hero-actions">
            <a
              className="marketing-cta"
              href="mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20demo%20request"
            >
              Talk to us about the product
            </a>
            <a className="marketing-secondary" href="#workflow">
              See how it works ↓
            </a>
          </div>
          <div
            className="store-downloads"
            id="download"
            aria-label="Download KartVizyon"
          >
            <a
              className="store-download-link"
              href={appStoreUrl}
              target="_blank"
              rel="noreferrer"
            >
              <span aria-hidden="true" className="store-download-icon">
                
              </span>
              <span>
                <small>iPhone and iPad</small>
                <strong>Download on the App Store</strong>
              </span>
            </a>
            <a
              className="store-download-link"
              href={playStoreUrl}
              target="_blank"
              rel="noreferrer"
            >
              <span
                aria-hidden="true"
                className="store-download-icon play-icon"
              >
                ▶
              </span>
              <span>
                <small>Android phones</small>
                <strong>Get it on Google Play</strong>
              </span>
            </a>
          </div>
          <small>
            Store availability and purchase terms depend on your store account
            and region.
          </small>
        </div>
        <div
          className="marketing-visual"
          aria-label="Illustrative customer visit workflow"
        >
          <div className="field-stamp" aria-hidden="true">
            <span>FIELD NOTE</span>
            <strong>14:32</strong>
          </div>
          <div className="product-frame">
            <div className="product-topbar">
              <span className="product-avatar">KV</span>
              <div>
                <small>Customer workspace</small>
                <strong>Visit briefing</strong>
              </div>
              <span className="sync-pill">● Ready</span>
            </div>
            <article className="brief-card">
              <div className="brief-heading">
                <span>RECENT CONTEXT</span>
                <strong>Atlas Medical</strong>
              </div>
              <p>Last visit: revised offer and delivery date need follow-up.</p>
            </article>
            <article className="brief-card">
              <div className="brief-heading">
                <span>AFTER THE VISIT</span>
                <strong>Review draft</strong>
              </div>
              <p>
                Transcript, AI summary, and suggested next step stay pending
                until approved.
              </p>
            </article>
          </div>
        </div>
      </section>

      <section className="marketing-proof" id="workflow">
        <div>
          <strong>01 · Prepare</strong>
          <span>Bring recent visits and open commitments into a briefing.</span>
        </div>
        <div>
          <strong>02 · Capture</strong>
          <span>Write or record your own post-visit debrief.</span>
        </div>
        <div>
          <strong>03 · Review</strong>
          <span>Edit the transcript and AI-generated draft.</span>
        </div>
        <div>
          <strong>04 · Follow up</strong>
          <span>Approve and turn commitments into trackable work.</span>
        </div>
      </section>

      <section
        className="marketing-section voice-demo-section"
        aria-labelledby="voice-demo-title"
      >
        <div className="section-heading">
          <span>FROM VOICE NOTE TO APPROVED FOLLOW-UP</span>
          <h2 id="voice-demo-title">
            “I met with the customer.” Make the next step count.
          </h2>
          <p>
            This fictional example illustrates the workflow. It is not a real
            recording or customer record.
          </p>
        </div>
        <div className="voice-demo-flow">
          <article className="voice-note-card">
            <div className="voice-card-label">
              <span className="voice-icon" aria-hidden="true">
                <svg viewBox="0 0 48 48" fill="none">
                  <rect x="18" y="5" width="12" height="24" rx="6" />
                  <path d="M11 22a13 13 0 0 0 26 0M24 35v8m-8 0h16" />
                  <path d="M5 13v8m38-8v8" />
                </svg>
              </span>
              <span>
                <strong>Sample voice note</strong>
                <small>Illustrative text · not an actual recording</small>
              </span>
            </div>
            <blockquote>
              “I met with the customer. Atlas Medical asked us to send a revised
              proposal by Friday and confirm the delivery date.”
            </blockquote>
            <div className="voice-wave" aria-hidden="true">
              {Array.from({ length: 25 }, (_, index) => (
                <i
                  key={index}
                  style={{ height: `${12 + ((index * 17) % 27)}px` }}
                />
              ))}
            </div>
            <small className="voice-note-caption">
              Example of a spoken field note
            </small>
          </article>
          <div className="voice-flow-arrow" aria-hidden="true">
            →
          </div>
          <article className="voice-result-card">
            <div className="voice-result-heading">
              <span>TRANSCRIPTION · AI DRAFT</span>
              <b>Needs review</b>
            </div>
            <div className="voice-transcript">
              <small>Speech-to-text</small>
              <p>
                I met with the customer. Atlas Medical asked us to send a
                revised proposal by Friday and confirm the delivery date.
              </p>
            </div>
            <h3>AI visit summary</h3>
            <p>
              Atlas Medical is waiting for a revised proposal. Send it by Friday
              and confirm the delivery date.
            </p>
            <div className="voice-followup">
              <span aria-hidden="true">↗</span>
              <span>
                <strong>Suggested follow-up</strong>
                <small>Friday · Send revised proposal</small>
              </span>
            </div>
            <small className="voice-approval-note">
              The AI draft is not added to the customer record until a user
              approves it.
            </small>
          </article>
        </div>
      </section>

      <section className="marketing-section" id="features">
        <div className="section-heading">
          <span>BUILT AROUND THE FIELD WORKFLOW</span>
          <h2>Useful before, during, and after each visit.</h2>
          <p>
            Designed to make customer context and promised next steps easier to
            find and act on.
          </p>
        </div>
        <div className="feature-grid">
          {features.map(([title, body], index) => (
            <article key={title} data-feature={`${index + 1}`.padStart(2, "0")}>
              <h3>{title}</h3>
              <p>{body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-section split-section" id="trust">
        <div>
          <span className="marketing-kicker">HUMAN REVIEW BY DEFAULT</span>
          <h2>AI can draft. People decide.</h2>
          <p>
            Review generated notes before they become shared customer memory.
            Workspace and role permissions govern access; location use is
            user-initiated or tied to visible Field Mode.
          </p>
          <Link className="marketing-secondary" href="/privacy">
            Read the privacy policy →
          </Link>
        </div>
        <ul className="trust-list">
          <li>Workspace- and role-scoped access</li>
          <li>AI summaries remain drafts until approved</li>
          <li>Uploaded documents are scanned before availability</li>
          <li>
            Data export and account-deletion requests are available in the
            product
          </li>
        </ul>
      </section>

      <section className="marketing-section pricing-section" id="pricing">
        <div className="section-heading">
          <span>PRICING</span>
          <h2>Start with your own field workflow.</h2>
          <p>
            Prices, currency, taxes, trial eligibility, and subscription terms
            shown by the relevant store at purchase take precedence.
          </p>
        </div>
        <article className="pricing-card">
          <h3>Individual · monthly</h3>
          <p>
            For Türkiye, the standard individual price is{" "}
            <strong>₺449/month including VAT</strong>. The store may show a
            different localized price for another account region.
          </p>
          <ul>
            <li>125 business-card scans per month</li>
            <li>240 minutes of audio processing per month</li>
            <li>125 AI summaries per month</li>
            <li>
              Unused allowances do not roll over; quota overage does not trigger
              an automatic extra charge
            </li>
          </ul>
          <p>
            Any free trial terms are shown in the purchase flow. Do not rely on
            trial availability until confirmed by your store account.
          </p>
        </article>
      </section>

      <section className="marketing-section faq-section" id="faq">
        <div className="section-heading">
          <span>FREQUENTLY ASKED QUESTIONS</span>
          <h2>Good to know</h2>
        </div>
        <div className="faq-list">
          {faqs.map(([q, a]) => (
            <details key={q}>
              <summary>{q}</summary>
              <p>{a}</p>
            </details>
          ))}
        </div>
      </section>

      <section className="marketing-final-cta">
        <div>
          <span>Keep the next customer commitment visible.</span>
          <h2>See whether KartVizyon fits your field-sales process.</h2>
        </div>
        <a
          className="marketing-cta light"
          href="mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20product%20conversation"
        >
          Request a product conversation <b>↗</b>
        </a>
      </section>

      <footer className="marketing-footer">
        <div className="footer-brand">
          <strong>KartVizyon</strong>
          <p>
            Noesis Social - Burak OHRİLİ
            <br />
            Bornova / İzmir · Türkiye
          </p>
          <p>
            <a href="tel:+905327449434">+90 532 744 94 34</a>
          </p>
        </div>
        <nav aria-label="Footer links">
          <div className="footer-col">
            <h4>Get the app</h4>
            <a href={appStoreUrl} target="_blank" rel="noreferrer">
              App Store
            </a>
            <a href={playStoreUrl} target="_blank" rel="noreferrer">
              Google Play
            </a>
          </div>
          <div className="footer-col">
            <h4>Company</h4>
            <Link href="/about">About</Link>
            <Link href="/contact">Contact</Link>
            <Link href="/support">Support</Link>
          </div>
          <div className="footer-col">
            <h4>Policies</h4>
            <Link href="/privacy">Privacy policy</Link>
            <Link href="/terms">Terms of use</Link>
            <Link href="/account-deletion">Account deletion</Link>
          </div>
        </nav>
        <small>
          © {new Date().getFullYear()} Noesis Social - Burak OHRİLİ. All rights
          reserved.
        </small>
      </footer>
    </main>
  );
}
