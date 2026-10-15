import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";
export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Gizlilik Politikası",
    englishTitle: "Privacy Policy",
    canonical: "https://kartvizyon.app/privacy",
  });
export default async function PrivacyPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="Privacy Policy"
        locale={locale}
        updated="September 12, 2026"
      >
        <p>
          This English notice is a market-preparation draft. It does not claim
          that KartVizyon is compliant with every UK, US federal, or US state
          privacy law. Your mandatory local rights apply where relevant. Before
          UK/US availability is enabled, we will publish the verified
          controller, provider, transfer, retention, and rights-request details
          for those markets. Contact us with questions or requests at any time.
        </p>
        <h2>Trials and subscription records</h2>
        <p>
          Trial start/end times, usage counters, and store transaction
          identifiers may be processed to provide the service, verify purchases,
          and prevent repeated trial use. KartVizyon does not collect payment
          card details; paid store purchases are managed by Apple or Google.
          Access to data-rights controls does not end when a trial expires.
          Account deletion is separate from subscription management, and legal
          retention duties may apply.
        </p>
        <h2>Data controller</h2>
        <p>
          KartVizyon is operated by Noesis Social - Burak OHRİLİ. For privacy
          requests, contact{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>.
        </p>
        <h2>Information we process</h2>
        <p>
          This may include account and profile details, workspace memberships,
          customer and visit records, audio, documents, business cards, and
          approximate location submitted through an explicit user action, as
          well as security and audit records.
        </p>
        <h2>Purposes and legal bases</h2>
        <p>
          Data may be processed to establish and provide the service, maintain
          security, provide support, meet legal obligations, and for analytics
          or AI purposes where consent has been given. Depending on the
          processing, the stated basis is contract performance, legitimate
          interests, legal obligation, or consent.
        </p>
        <h2>AI and human review</h2>
        <p>
          Summaries generated from audio and notes are drafts. They are not
          added as confirmed organizational memory without user approval. AI
          inputs are not used for advertising profiling.
        </p>
        <h2>Retention and security</h2>
        <p>
          Raw audio is retained for a limited period and then scheduled for
          deletion under the policy. Documents are not made available until
          malware scanning reports a clean result. Access is restricted by
          tenant, role, and workspace rules. Do not infer a particular
          encryption or provider-retention guarantee from this description.
        </p>
        <h2>Service providers and transfers</h2>
        <p>
          Supabase may provide hosting and identity services, OpenAI AI
          processing, Sentry error monitoring, RevenueCat mobile subscription
          verification, and Apple or Google store/payment functions. Only data
          needed for the service should be shared with each provider.
          International transfers are subject to the applicable legal safeguards
          and transfer documentation; those arrangements must be verified before
          a new market launch.
        </p>
        <h2>Payment data</h2>
        <p>
          KartVizyon does not see or store full payment-card or store-payment
          details. Limited records such as store, product, transaction ID,
          subscription status, and period end may be retained to provide
          entitlements, prevent fraud, and support users.
        </p>
        <h2>Your rights</h2>
        <p>
          The in-app privacy and data-rights center lets you request a data
          export, withdraw consent, and initiate account deletion. You may also
          contact us to request access, correction, deletion, restriction, or
          objection where those rights apply. UK users may have rights to
          access, rectify, erase, restrict or object to processing, and data
          portability, and may complain to the Information Commissioner&apos;s
          Office. US rights vary by state and applicability; they may include
          access/know, correction, deletion, portability, and opting out of
          certain sale, sharing, or targeted-advertising processing. We will
          verify and operationalize applicable state-specific request and appeal
          processes before enabling US availability. A request interface does
          not mean processing is immediate or already complete. Contact{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>{" "}
          to exercise a right or ask a question.
        </p>
        <h2>UK and international processing</h2>
        <p>
          For UK users, the controller must identify and document an appropriate
          lawful basis for each processing purpose and provide it in the final
          privacy information. If personal information is transferred outside
          the UK, the applicable UK transfer mechanism and any required transfer
          risk assessment must be confirmed for the actual recipient and route.
          Provider locations, onward transfers, and contract safeguards are
          being verified; this draft is not evidence that those checks are
          complete.
        </p>
        <h2>US state privacy disclosures</h2>
        <p>
          US privacy laws differ by state and can depend on the business,
          processing, and statutory applicability thresholds. Before launch, we
          must verify the categories and sources of information, purposes,
          disclosures to service providers, any sale/share or targeted
          advertising activity, retention periods, applicable rights, and the
          request/appeal channels. This draft does not assert that KartVizyon
          sells or shares personal information, or that a particular state law
          applies; those facts must be checked against actual operations and
          contracts.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="Gizlilik Politikası" locale={locale}>
      <h2>Deneme ve abonelik kayıtları</h2>
      <p>
        Denemenin başlangıç/bitiş zamanı, kullanım sayaçları ve mağaza işlem
        kimlikleri; hizmetin sunulması, satın almaların doğrulanması ve tekrar
        deneme kullanımının önlenmesi için işlenir. Kart bilgileri KartVizyon
        tarafından alınmaz; ücretli mağaza satın almaları Apple veya Google
        tarafından yönetilir. Deneme bittiğinde veri hakları erişimi kapanmaz.
        Hesap silme talebi abonelik yönetiminden ayrı yürütülür; yasal saklama
        yükümlülükleri saklıdır.
      </p>
      <h2>Veri sorumlusu</h2>
      <p>
        KartVizyon, Noesis Social - Burak OHRİLİ tarafından işletilir. Gizlilik
        talepleri için kartvizyonapp@gmail.com adresine ulaşabilirsiniz.
      </p>
      <h2>İşlediğimiz veriler</h2>
      <p>
        Hesap ve profil bilgileri, çalışma alanı üyelikleri, müşteri ve ziyaret
        kayıtları, kullanıcının açık işlemiyle eklediği ses, belge, kartvizit ve
        yaklaşık konum verileri ile güvenlik/audit kayıtları işlenebilir.
      </p>
      <h2>Amaç ve hukuki sebep</h2>
      <p>
        Veriler hizmetin kurulması ve sunulması, güvenlik, destek, yasal
        yükümlülükler ve açık rıza verilen analitik/AI amaçlarıyla; sözleşmenin
        ifası, meşru menfaat, hukuki yükümlülük veya açık rızaya dayanarak
        işlenir.
      </p>
      <h2>AI ve insan kontrolü</h2>
      <p>
        Ses ve notlardan oluşturulan özetler taslaktır. Kullanıcı onayı olmadan
        kurumsal hafızaya kesin kayıt olarak eklenmez. AI girdileri reklam
        profillemesi amacıyla kullanılmaz.
      </p>
      <h2>Saklama ve güvenlik</h2>
      <p>
        Ham ses süreli saklanır ve politika sonunda silinir. Belgeler zararlı
        yazılım taramasından temiz sonuç almadan açılamaz. Erişim tenant, rol ve
        çalışma alanı kurallarıyla sınırlandırılır.
      </p>
      <h2>Aktarımlar ve hizmet sağlayıcılar</h2>
      <p>
        Barındırma ve kimlik için Supabase, AI işleme için OpenAI, hata izleme
        için Sentry, mobil abonelik doğrulama için RevenueCat; ödeme ve mağaza
        hesabı işlemleri için Apple veya Google kullanılabilir. Bu sağlayıcılara
        yalnız hizmet için gerekli veri aktarılır. Yurt dışı aktarımlarda KVKK
        madde 9 kapsamındaki uygun güvence mekanizması, aktarım envanteri ve
        gerekli standart sözleşme/bildirim adımları tamamlanır.
      </p>
      <h2>Ödeme verileri</h2>
      <p>
        KartVizyon tam kart veya mağaza ödeme bilgilerini görmez ve saklamaz.
        Mağaza, ürün, işlem kimliği, abonelik durumu ve dönem sonu gibi hak
        tanımlamak için gerekli sınırlı kayıtlar sahteciliği önleme ve destek
        amacıyla tutulur.
      </p>
      <h2>Haklarınız</h2>
      <p>
        Uygulamadaki KVKK ve veri hakları merkezinden verilerinizi dışa
        aktarabilir, rızaları geri alabilir ve hesabınızın silinmesini
        başlatabilirsiniz.
      </p>
    </LegalPage>
  );
}
