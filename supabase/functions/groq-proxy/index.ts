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
        // Check if handling image analysis (custom structure) or standard chat completion
        const body = await req.json();

        // Default endpoint for chat completions
        let apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

        // Extract parameters
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
                model: model || 'llama-3.1-70b-versatile',
                messages,
                temperature: temperature || 0.7,
                max_tokens: max_tokens || 2048,
            }),
        });

        const data = await response.json();

        return new Response(JSON.stringify(data), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: response.status,
        });
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        });
    }
});
