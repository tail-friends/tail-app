const encoder = new TextEncoder();

function constantTimeEqual(left, right) {
  const a = encoder.encode(left || "");
  const b = encoder.encode(right || "");
  let difference = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let index = 0; index < length; index += 1) {
    difference |= (a[index % Math.max(a.length, 1)] || 0) ^
      (b[index % Math.max(b.length, 1)] || 0);
  }
  return difference === 0;
}

function response(message, status = 200) {
  return new Response(JSON.stringify({ message }), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return response("method not allowed", 405);
    if (!env.FIGMA_WEBHOOK_PASSCODE || !env.GITHUB_DISPATCH_TOKEN) {
      return response("receiver is not configured", 500);
    }
    if (!request.headers.get("content-type")?.includes("application/json")) {
      return response("content type must be application/json", 415);
    }
    const declaredLength = Number(request.headers.get("content-length") || 0);
    if (declaredLength > 65536) return response("payload too large", 413);

    const rawBody = await request.text();
    if (encoder.encode(rawBody).byteLength > 65536) {
      return response("payload too large", 413);
    }

    let payload;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return response("invalid json", 400);
    }

    if (!constantTimeEqual(payload.passcode, env.FIGMA_WEBHOOK_PASSCODE)) {
      return response("unauthorized", 401);
    }
    if (payload.event_type === "PING") return response("pong");
    if (payload.event_type !== "FILE_VERSION_UPDATE") {
      return response("event ignored");
    }
    if (payload.file_key !== env.FIGMA_FILE_KEY) {
      return response("file ignored");
    }
    if (!payload.version_id || !payload.webhook_id) {
      return response("missing event identifiers", 400);
    }

    const eventKey = `${payload.webhook_id}:${payload.version_id}`;
    if (env.EVENTS && await env.EVENTS.get(eventKey)) {
      return response("duplicate ignored");
    }

    const repository = env.GITHUB_REPOSITORY;
    if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository || "")) {
      return response("receiver is not configured", 500);
    }
    const githubResponse = await fetch(
      `https://api.github.com/repos/${repository}/dispatches`,
      {
        method: "POST",
        headers: {
          accept: "application/vnd.github+json",
          authorization: `Bearer ${env.GITHUB_DISPATCH_TOKEN}`,
          "content-type": "application/json",
          "user-agent": "tail-friends-figma-webhook",
          "x-github-api-version": "2022-11-28",
        },
        body: JSON.stringify({
          event_type: "figma-version-update",
          client_payload: {
            file_key: payload.file_key,
            version_id: String(payload.version_id),
            label: String(payload.label || ""),
            webhook_id: String(payload.webhook_id),
          },
        }),
      },
    );
    if (!githubResponse.ok) {
      return response("github dispatch failed", 502);
    }

    if (env.EVENTS) {
      await env.EVENTS.put(eventKey, "processed", { expirationTtl: 604800 });
    }
    return response("accepted", 202);
  },
};
