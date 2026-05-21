// api/send.js
// Vercel Serverless Function to relay PIN emails using Resend or SendGrid.
// Configure RESEND_API_KEY or SENDGRID_API_KEY in your Vercel Project Environment Variables.

import { Resend } from 'resend';
import sgMail from '@sendgrid/mail';

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

  // 1. Try sending via Resend if RESEND_API_KEY is configured
  if (process.env.RESEND_API_KEY) {
    try {
      const resend = new Resend(process.env.RESEND_API_KEY);
      const data = await resend.emails.send({
        from: 'Lockit <noreply@yourdomain.com>', // Replace with your verified sending domain
        to: [guardianEmail],
        subject: `Lockit Key: ${guardianName}`,
        html: `
          <div style="font-family: sans-serif; padding: 24px; color: #333;">
            <h2>Hello ${guardianName},</h2>
            <p>${message || 'Your friend is using Lockit to find some space. Please keep this safe.'}</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
            <p style="font-size: 14px; color: #666;">Here is their vault security PIN:</p>
            <p style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #4A4A6A; margin: 12px 0;">${pin}</p>
            <p style="font-size: 12px; color: #999;">Do not share this PIN with anyone unless they ask to open their vault.</p>
          </div>
        `
      });
      return res.status(200).json({ message: 'Email sent successfully via Resend', id: data.id });
    } catch (error) {
      console.error('Error sending with Resend:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  // 2. Try sending via SendGrid if SENDGRID_API_KEY is configured
  if (process.env.SENDGRID_API_KEY) {
    try {
      sgMail.setApiKey(process.env.SENDGRID_API_KEY);
      const msg = {
        to: guardianEmail,
        from: 'noreply@yourdomain.com', // Replace with your verified sending domain
        subject: `Lockit Key: ${guardianName}`,
        html: `
          <div style="font-family: sans-serif; padding: 24px; color: #333;">
            <h2>Hello ${guardianName},</h2>
            <p>${message || 'Your friend is using Lockit to find some space. Please keep this safe.'}</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
            <p style="font-size: 14px; color: #666;">Here is their vault security PIN:</p>
            <p style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #4A4A6A; margin: 12px 0;">${pin}</p>
            <p style="font-size: 12px; color: #999;">Do not share this PIN with anyone unless they ask to open their vault.</p>
          </div>
        `
      };
      await sgMail.send(msg);
      return res.status(200).json({ message: 'Email sent successfully via SendGrid' });
    } catch (error) {
      console.error('Error sending with SendGrid:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  // 3. Fallback error if no provider key is configured
  return res.status(500).json({
    error: 'No email service provider configured on the server. Please set RESEND_API_KEY or SENDGRID_API_KEY.'
  });
}
