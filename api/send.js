// api/send.js
// Vercel Serverless Function to relay PIN emails using Resend or SendGrid via native fetch.
// No package.json or external dependencies required!

export default async function handler(req, res) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { guardianEmail, guardianName, pin, message } = req.body;

  if (!guardianEmail || !pin) {
    return res.status(400).json({ error: 'Missing required fields: guardianEmail and pin' });
  }

  const emailHtml = `
    <div style="font-family: sans-serif; padding: 24px; color: #333;">
      <h2>Hello ${guardianName},</h2>
      <p>${message || 'Your friend is using Lockit to find some space. Please keep this safe.'}</p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
      <p style="font-size: 14px; color: #666;">Here is their vault security PIN:</p>
      <p style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #4A4A6A; margin: 12px 0;">${pin}</p>
      <p style="font-size: 12px; color: #999;">Do not share this PIN with anyone unless they ask to open their vault.</p>
    </div>
  `;

  // 1. Try sending via Resend REST API if RESEND_API_KEY is configured
  if (process.env.RESEND_API_KEY) {
    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          from: 'Lockit <onboarding@resend.dev>', // Resend sandbox default (replace with your domain in production)
          to: [guardianEmail],
          subject: `Lockit Key: ${guardianName}`,
          html: emailHtml
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Resend API returned an error');
      }

      return res.status(200).json({ message: 'Email sent successfully via Resend API', id: data.id });
    } catch (error) {
      console.error('Error sending with Resend API:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  // 2. Try sending via SendGrid REST API if SENDGRID_API_KEY is configured
  if (process.env.SENDGRID_API_KEY) {
    try {
      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.SENDGRID_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          personalizations: [{ to: [{ email: guardianEmail }] }],
          from: { email: 'noreply@yourdomain.com', name: 'Lockit' },
          subject: `Lockit Key: ${guardianName}`,
          content: [{ type: 'text/html', value: emailHtml }]
        })
      });

      if (!response.ok) {
        const text = await response.text();
        throw new Error(`SendGrid API returned status ${response.status}: ${text}`);
      }

      return res.status(200).json({ message: 'Email sent successfully via SendGrid API' });
    } catch (error) {
      console.error('Error sending with SendGrid API:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  // 3. Fallback error if no provider key is configured
  return res.status(500).json({
    error: 'No email service provider configured on Vercel. Please set RESEND_API_KEY or SENDGRID_API_KEY in Vercel environment variables.'
  });
}
