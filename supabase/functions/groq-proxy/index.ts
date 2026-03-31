import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const body = await req.json();

        const apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

        // Extract parameters - messages can contain multimodal content (text + images)
        const { model, messages, temperature, max_tokens } = body;

        const apiKey = Deno.env.get('GROQ_API_KEY');
        if (!apiKey) {
            throw new Error('GROQ_API_KEY is not set');
        }

        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: model || 'llama-3.3-70b-versatile',
                messages,
                temperature: temperature || 0.7,
                max_tokens: max_tokens || 2048,
            }),
        });

        // Handle non-JSON error responses from Groq
        const responseText = await response.text();
        let data;
        try {
            data = JSON.parse(responseText);
        } catch {
            return new Response(JSON.stringify({ 
                error: `Groq API error (${response.status}): ${responseText.substring(0, 500)}` 
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: response.status,
            });
        }

        // If Groq returned an error, forward it with details
        if (!response.ok) {
            const errorMsg = data?.error?.message || JSON.stringify(data);
            return new Response(JSON.stringify({ 
                error: `Groq API error: ${errorMsg}`,
                details: data 
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: response.status,
            });
        }

        return new Response(JSON.stringify(data), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        });
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        });
    }
});
