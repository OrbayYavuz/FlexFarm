// @ts-nocheck
// Supabase Edge Function: push-notification
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { SignJWT, importPKCS8 } from "https://esm.sh/jose@4.14.4"

console.log("Push Notification Function Started!")

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const body = await req.json().catch(() => null)
        if (!body || !body.record) {
            return new Response(JSON.stringify({ message: 'No record' }), { headers: corsHeaders })
        }

        const { receiver_id, message, sender_id, listing_id } = body.record

        // Supabase Client
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 1. Alıcının Token'ını ve Gönderenin Adını Bul
        const [receiverRes, senderRes] = await Promise.all([
            supabase.from('profiles').select('fcm_token').eq('id', receiver_id).single(),
            supabase.from('profiles').select('name').eq('id', sender_id).single()
        ])

        const fcmToken = receiverRes.data?.fcm_token
        const senderName = senderRes.data?.name ?? 'Bir kullanıcı'

        if (!fcmToken) {
            console.log('Alıcının tokeni yok, atlanıyor.')
            return new Response(JSON.stringify({ message: 'No token' }), { headers: corsHeaders })
        }

        // 2. Google Access Token Al (Service Account ile)
        const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
        if (!serviceAccountStr) {
            throw new Error('FIREBASE_SERVICE_ACCOUNT secret is missing!')
        }
        const serviceAccount = JSON.parse(serviceAccountStr)
        const accessToken = await getAccessToken(serviceAccount)

        // 3. Bildirimi Gönder (FCM v1 API)
        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

        const notificationPayload = {
            message: {
                token: fcmToken,
                notification: {
                    title: `Yeni Mesaj: ${senderName}`,
                    body: message
                },
                data: {
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    type: 'chat',
                    listing_id: listingId ? String(listingId) : '',
                    sender_id: String(sender_id),
                    sender_name: senderName
                }
            }
        }

        const response = await fetch(fcmUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(notificationPayload)
        })

        const resData = await response.json()
        console.log('FCM Response:', resData)

        if (!response.ok) {
            throw new Error(`FCM Error: ${JSON.stringify(resData)}`)
        }

        return new Response(
            JSON.stringify({ success: true, message: 'Notification Sent!' }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )

    } catch (error) {
        console.error('Hata:', error)
        return new Response(
            JSON.stringify({ error: String(error) }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )
    }
})

// Google OAuth2 Token Üretme Fonksiyonu
async function getAccessToken(serviceAccount: any) {
    const Algorithm = 'RS256'
    const pkcs8 = await importPKCS8(serviceAccount.private_key, Algorithm)

    const jwt = await new SignJWT({
        scope: 'https://www.googleapis.com/auth/firebase.messaging'
    })
        .setProtectedHeader({ alg: Algorithm })
        .setIssuer(serviceAccount.client_email)
        .setAudience('https://oauth2.googleapis.com/token')
        .setExpirationTime('1h')
        .setIssuedAt()
        .sign(pkcs8)

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt
        })
    })

    const tokenData = await tokenRes.json()
    return tokenData.access_token
}
