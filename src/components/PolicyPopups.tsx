import React from 'react';

interface PolicyPopupProps {
  isOpen: boolean;
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}

const PolicyPopup: React.FC<PolicyPopupProps> = ({ isOpen, title, onClose, children }) => {
  if (!isOpen) return null;
  
  return (
    <div 
      className="policy-popup-overlay" 
      onClick={onClose}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        background: 'rgba(0, 0, 0, 0.8)',
        zIndex: 3000,
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        backdropFilter: 'blur(3px)'
      }}
    >
      <div 
        className="policy-popup"
        onClick={(e) => e.stopPropagation()}
        style={{
          background: '#222',
          borderRadius: '12px',
          width: '90%',
          maxWidth: '600px',
          maxHeight: '80vh',
          padding: '20px',
          color: 'white',
          boxShadow: '0 10px 25px rgba(0, 0, 0, 0.5)',
          display: 'flex',
          flexDirection: 'column'
        }}
      >
        <h3 style={{ fontSize: '24px', marginBottom: '15px', color: 'white', textAlign: 'center' }}>
          {title}
        </h3>
        <div 
          className="policy-content"
          style={{
            overflowY: 'auto',
            flex: 1,
            padding: '10px 0',
            marginBottom: '20px',
            lineHeight: 1.6
          }}
        >
          {children}
        </div>
        <button 
          className="policy-close-button"
          onClick={onClose}
          style={{
            background: '#333',
            color: 'white',
            border: 'none',
            padding: '12px 15px',
            borderRadius: '6px',
            fontSize: '16px',
            cursor: 'pointer'
          }}
        >
          Close
        </button>
      </div>
    </div>
  );
};

export const TermsPopup: React.FC<{ isOpen: boolean; onClose: () => void }> = ({ isOpen, onClose }) => (
  <PolicyPopup isOpen={isOpen} title="TERMS OF SERVICE" onClose={onClose}>
    <h4>1. Acceptance of Terms</h4>
    <p>By accessing and using Fast Check-In's services, features, content, or applications (collectively, the "Service"), you agree to comply with and be bound by these Terms of Service and our Privacy Policy (the "Terms"). If you do not agree with these Terms, you must discontinue use of the Service immediately.</p>
    <p>These Terms constitute a legally binding agreement between you and Fast Check-In. We reserve the right to update and modify these Terms at any time. Your continued use of our Service after modifications indicates your acceptance of the revised Terms.</p>

    <h4>2. User Account</h4>
    <p>To access certain features of the Service, you may be required to create an account and provide accurate, complete, and current information. You may not create an account using false information, impersonate others, or create multiple accounts for abusive purposes. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.</p>
    <p>Accounts cannot be created by individuals under the age of 13. If we discover that an account has been created by someone under this age, we will terminate it immediately.</p>

    <h4>3. Scope of Service</h4>
    <p>Fast Check-In offers a range of services designed to facilitate customer check-ins, loyalty tracking, and automated messaging. The specific features available to you may vary based on the plan you have subscribed to. Additional fees may apply for certain premium services. We reserve the right to modify or discontinue any feature at any time.</p>

    <h4>4. Express Written Consent</h4>
    <p>By registering with Fast Check-In, you agree to receive marketing communications via SMS or phone calls. These communications may be sent using an automated system. You understand that consent to receive marketing communications is not required to use our services, and you may opt out at any time by following the instructions in our messages.</p>

    <h4>5. Prohibited Uses</h4>
    <p>You agree not to misuse the Service. Prohibited activities include, but are not limited to:</p>
    <ul style={{ marginLeft: "20px", listStyleType: "disc" }}>
      <li>Impersonating Fast Check-In or other users.</li>
      <li>Disrupting, modifying, or interfering with the Service.</li>
      <li>Engaging in spam, phishing, or fraudulent activities.</li>
      <li>Violating any applicable laws or regulations.</li>
      <li>Using the Service to harass, threaten, or harm others.</li>
      <li>Attempting to gain unauthorized access to Fast Check-In's systems or data.</li>
    </ul>
    <p>Violation of these Terms may result in immediate termination of your account.</p>

    <h4>6. Compliance with Laws</h4>
    <p>You must comply with all applicable local, state, national, and international laws, including the Telephone Consumer Protection Act (TCPA) and Telemarketing Sales Rule. You are solely responsible for ensuring that your use of the Service adheres to these laws.</p>

    <h4>7. No Resale of Service</h4>
    <p>You may not resell, distribute, or commercially exploit the Service without explicit written permission from Fast Check-In. Unauthorized resale may result in termination of service and legal action.</p>

    <h4>8. Termination of Service</h4>
    <p>Fast Check-In reserves the right to suspend or terminate your access to the Service at any time for violations of these Terms, including but not limited to:</p>
    <ul style={{ marginLeft: "20px", listStyleType: "disc" }}>
      <li>Fraudulent activity</li>
      <li>Abuse of the platform</li>
      <li>Unauthorized access</li>
      <li>Violation of applicable laws</li>
      <li>Any behavior that disrupts or negatively impacts other users or the integrity of the Service</li>
    </ul>
    <p>You may discontinue your use of the Service at any time. Termination of service does not relieve you of any outstanding payment obligations.</p>

    <h4>9. Modifications to Service</h4>
    <p>We reserve the right to modify, suspend, or discontinue any part of the Service at our discretion without prior notice. Fast Check-In is not liable for any changes that may affect your access to or use of the Service.</p>

    <h4>10. Intellectual Property</h4>
    <p>All content, software, and trademarks associated with the Service are the property of Fast Check-In. You may not reproduce, distribute, modify, or create derivative works based on any Fast Check-In content without prior written permission.</p>
    <p>Any unauthorized use of our intellectual property may result in legal action.</p>

    <h4>11. Privacy</h4>
    <p>Your use of the Service is subject to our Privacy Policy, which governs how we collect, use, and protect your information. You can review our Privacy Policy at Privacy Policy.</p>

    <h4>12. Disclaimers and Limitation of Liability</h4>
    <p>The Service is provided "as is" and "as available" without warranties of any kind. Fast Check-In disclaims all warranties, express or implied, including but not limited to:</p>
    <ul style={{ marginLeft: "20px", listStyleType: "disc" }}>
      <li>Warranties of merchantability</li>
      <li>Fitness for a particular purpose</li>
      <li>Non-infringement</li>
    </ul>
    <p>Fast Check-In is not liable for any indirect, incidental, or consequential damages arising from your use of the Service.</p>

    <h4>13. Indemnification</h4>
    <p>You agree to indemnify, defend, and hold harmless Fast Check-In from any claims, damages, or expenses (including legal fees) arising from:</p>
    <ul style={{ marginLeft: "20px", listStyleType: "disc" }}>
      <li>Your use of the Service</li>
      <li>Violation of these Terms</li>
      <li>Any third-party claims related to your content or activities on the platform</li>
    </ul>

    <h4>14. Choice of Law and Arbitration</h4>
    <p>These Terms are governed by the laws of the State of Arizona, unless otherwise required by applicable law. Any disputes arising out of or related to these Terms or the Service shall be resolved through binding arbitration administered by the American Arbitration Association (AAA) in accordance with its Commercial Arbitration Rules. The arbitration shall be held in Phoenix, Arizona, and judgment on the award rendered by the arbitrator(s) may be entered in any court having jurisdiction.</p>
    <p>Waiver of Class Actions: You expressly waive your right to participate in any class action lawsuits or class-wide arbitration proceedings against Fast Check-In. Arbitration shall be conducted solely on an individual basis, and you shall not join or consolidate claims with others.</p>
    <p>Exceptions to Arbitration: You and Fast Check-In agree that the following disputes are not subject to the above arbitration provision:</p>
    <ul style={{ marginLeft: "20px", listStyleType: "disc" }}>
      <li>Any disputes that qualify for small claims court.</li>
      <li>Any claims involving allegations of intellectual property infringement.</li>
      <li>Any action seeking injunctive or equitable relief.</li>
    </ul>
    <p>If arbitration is found to be unenforceable in your jurisdiction, disputes must be resolved in the appropriate courts located in Phoenix, Arizona.</p>

    <h4>15. Contact Information</h4>
    <p>For any questions regarding these Terms, contact us at:</p>
    <p>Fast Check-In LLC<br />
    949-899-7999<br />
    contact@fastcheckin.net<br />
    2325 East Camelback Rd. Suite 400, Phoenix, AZ 85016</p>

    <h4>16. Changes to Terms</h4>
    <p>We reserve the right to update these Terms at any time. Changes will be posted on our website, and continued use of the Service after modifications constitutes acceptance of the updated Terms. If a revision is material, we will attempt to provide at least 30 days' notice before new terms take effect.</p>

    <h4>17. Mobile Services</h4>
    <p>Fast Check-In may offer mobile-based services, including SMS notifications and mobile check-in features. Standard message and data rates may apply based on your wireless carrier. You may opt out of SMS notifications at any time by replying STOP to any message received. For further assistance, reply HELP or contact customer support at contact@fastcheckin.net.</p>

    <h4>18. Force Majeure</h4>
    <p>Fast Check-In shall not be held liable for any failure or delay in performance due to circumstances beyond our reasonable control, including but not limited to acts of God, natural disasters, government restrictions, labor strikes, and disruptions in telecommunications.</p>

    <h4>19. Severability</h4>
    <p>If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions shall remain in full force and effect. Any unenforceable provision shall be modified to the extent necessary to make it enforceable while preserving the original intent.</p>
  </PolicyPopup>
);

export const PrivacyPopup: React.FC<{ isOpen: boolean; onClose: () => void }> = ({ isOpen, onClose }) => (
  <PolicyPopup isOpen={isOpen} title="Privacy Policy" onClose={onClose}>
    <p>This Privacy Policy describes how we collect, use, and share your personal information when you use our Service.</p>
    <h4 style={{ fontSize: '18px', margin: '15px 0 5px', color: '#ddd' }}>1. Information We Collect</h4>
    <p>We collect information you provide directly to us, including your name, phone number, and birth month when you check in using our Service.</p>
    <h4 style={{ fontSize: '18px', margin: '15px 0 5px', color: '#ddd' }}>2. How We Use Your Information</h4>
    <p>We use the information we collect to provide, maintain, and improve our Service, communicate with you about wait times, check-in status, and send promotional offers.</p>
    <h4 style={{ fontSize: '18px', margin: '15px 0 5px', color: '#ddd' }}>3. Text Message Communications</h4>
    <p>With your consent, we may send text messages to your provided phone number about check-in confirmations, wait time updates, and promotional offers.</p>
    <h4 style={{ fontSize: '18px', margin: '15px 0 5px', color: '#ddd' }}>4. Information Sharing</h4>
    <p>We do not share or sell any data collected. The data collected is for sole use of FastCheckin service.</p>
  </PolicyPopup>
);