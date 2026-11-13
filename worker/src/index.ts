export interface Env {
  GEMINI_API_KEY?: string;
}

const MAX_BODY_BYTES = 16 * 1024 * 1024; // 16 MB
const RATE_LIMIT_WINDOW_MS = 60_000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 30;

const ALLOWED_PATHS = new Set<string>([
  '/v1beta/models/gemini-2.5-flash:generateContent',
  '/v1beta/models/gemini-flash-latest:generateContent',
]);

// Per-isolate in-memory sliding window keyed by client IP.
const ipRequestLog = new Map<string, number[]>();

function isAllowedOrigin(origin: string): boolean {
  let parsed: URL;
  try {
    parsed = new URL(origin);
  } catch {
    return false;
  }

  if (
    parsed.origin !== origin.toLowerCase() ||
    parsed.pathname !== '/' ||
    parsed.search !== '' ||
    parsed.hash !== '' ||
    parsed.username !== '' ||
    parsed.password !== ''
  ) {
    return false;
  }

  if (
    parsed.protocol === 'https:' &&
    parsed.hostname === 'tobishakur.github.io' &&
    parsed.port === ''
  ) {
    return true;
  }

  if (
    parsed.protocol === 'http:' &&
    (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1')
  ) {
    return true;
  }

  return false;
}

function buildCorsHeaders(origin: string | null): Record<string, string> {
  const headers: Record<string, string> = {
    Vary: 'Origin',
  };
  if (origin) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS';
    headers['Access-Control-Allow-Headers'] = 'Content-Type';
    headers['Access-Control-Max-Age'] = '86400';
  }
  return headers;
}

function jsonResponse(
  status: number,
  payload: Record<string, unknown>,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...extraHeaders,
    },
  });
}

function checkRateLimit(
  ip: string,
  now: number,
): { allowed: boolean; remaining: number; resetSeconds: number } {
  if (ipRequestLog.size > 1000) {
    const cutoff = now - RATE_LIMIT_WINDOW_MS;
    for (const [key, timestamps] of ipRequestLog.entries()) {
      const active = timestamps.filter((t) => t > cutoff);
      if (active.length === 0) {
        ipRequestLog.delete(key);
      } else {
        ipRequestLog.set(key, active);
      }
    }
  }

  const cutoff = now - RATE_LIMIT_WINDOW_MS;
  const recent = (ipRequestLog.get(ip) ?? []).filter((t) => t > cutoff);

  if (recent.length >= RATE_LIMIT_MAX_REQUESTS) {
    const resetMs = Math.max(1000, recent[0] + RATE_LIMIT_WINDOW_MS - now);
    ipRequestLog.set(ip, recent);
    return {
      allowed: false,
      remaining: 0,
      resetSeconds: Math.ceil(resetMs / 1000),
    };
  }

  recent.push(now);
  ipRequestLog.set(ip, recent);
  const resetMs = Math.max(1000, recent[0] + RATE_LIMIT_WINDOW_MS - now);
  return {
    allowed: true,
    remaining: RATE_LIMIT_MAX_REQUESTS - recent.length,
    resetSeconds: Math.ceil(resetMs / 1000),
  };
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get('Origin');
    if (origin !== null && !isAllowedOrigin(origin)) {
      return jsonResponse(
        403,
        { error: 'Forbidden origin' },
        { Vary: 'Origin' },
      );
    }

    const corsHeaders = buildCorsHeaders(origin);

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    if (request.method !== 'POST') {
      return jsonResponse(
        405,
        { error: 'Method not allowed' },
        { ...corsHeaders, Allow: 'POST, OPTIONS' },
      );
    }

    const url = new URL(request.url);
    if (!ALLOWED_PATHS.has(url.pathname)) {
      return jsonResponse(404, { error: 'Not found' }, corsHeaders);
    }

    const clientIp = request.headers.get('CF-Connecting-IP') ?? 'unknown';
    const rateLimit = checkRateLimit(clientIp, Date.now());
    const rateLimitHeaders: Record<string, string> = {
      'X-RateLimit-Limit': String(RATE_LIMIT_MAX_REQUESTS),
      'X-RateLimit-Remaining': String(rateLimit.remaining),
      'X-RateLimit-Reset': String(rateLimit.resetSeconds),
    };

    if (!rateLimit.allowed) {
      return jsonResponse(
        429,
        { error: 'Too many requests' },
        {
          ...corsHeaders,
          ...rateLimitHeaders,
          'Retry-After': String(rateLimit.resetSeconds),
        },
      );
    }

    const apiKey = env.GEMINI_API_KEY?.trim();
    if (!apiKey) {
      return jsonResponse(
        500,
        { error: 'Internal server error' },
        corsHeaders,
      );
    }

    const contentLengthHeader = request.headers.get('Content-Length');
    if (contentLengthHeader !== null) {
      const contentLength = Number(contentLengthHeader);
      if (!Number.isFinite(contentLength) || contentLength < 0) {
        return jsonResponse(
          400,
          { error: 'Invalid Content-Length header' },
          corsHeaders,
        );
      }
      if (contentLength > MAX_BODY_BYTES) {
        return jsonResponse(413, { error: 'Payload too large' }, corsHeaders);
      }
    }

    const bodyBuffer = await request.arrayBuffer();
    if (bodyBuffer.byteLength > MAX_BODY_BYTES) {
      return jsonResponse(413, { error: 'Payload too large' }, corsHeaders);
    }
    if (bodyBuffer.byteLength === 0) {
      return jsonResponse(400, { error: 'Empty request body' }, corsHeaders);
    }

    const upstreamUrl = `https://generativelanguage.googleapis.com${url.pathname}`;

    try {
      const upstreamResponse = await fetch(upstreamUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: bodyBuffer,
      });

      const responseHeaders = new Headers(corsHeaders);
      responseHeaders.set(
        'Content-Type',
        upstreamResponse.headers.get('Content-Type') ??
          'application/json; charset=utf-8',
      );
      responseHeaders.set('X-RateLimit-Limit', String(RATE_LIMIT_MAX_REQUESTS));
      responseHeaders.set('X-RateLimit-Remaining', String(rateLimit.remaining));
      responseHeaders.set('X-RateLimit-Reset', String(rateLimit.resetSeconds));

      return new Response(upstreamResponse.body, {
        status: upstreamResponse.status,
        headers: responseHeaders,
      });
    } catch {
      return jsonResponse(
        502,
        { error: 'Upstream service unavailable' },
        corsHeaders,
      );
    }
  },
};
