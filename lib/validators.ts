import { z } from "zod";
export const signupSchema = z.object({ name: z.string().min(2), email: z.string().email(), password: z.string().min(8) });
export const contactSchema = z.object({ name: z.string().min(2), businessName: z.string().min(2), phone: z.string().min(6), email: z.string().email(), businessType: z.string().min(2), serviceNeeded: z.string().min(2), message: z.string().min(5) });
export const bookingSchema = z.object({ name: z.string().min(2), email: z.string().email(), phone: z.string().min(6), service: z.string().min(2), preferredDate: z.string(), preferredTime: z.string(), message: z.string().optional() });
export const demoSchema = z.object({ conversationId: z.string().optional(), message: z.string().min(1) });
