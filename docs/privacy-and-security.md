# Privacy and Security

Threadbase is designed around local ownership and explicit control.

## Local-first privacy model

- AI coding-agent sessions run on your machine.
- History is indexed locally.
- Mobile clients connect to streamers you configure.
- Threadbase does not require hosting or inspecting private session content.
- Optional hosted capabilities, if introduced, should remain opt-in.

Privacy policy:

https://threadbase.sh/privacy

## Security guidance

- Keep streamer API keys private.
- Prefer HTTPS when exposing streamer outside localhost.
- Use pairing flows instead of sharing keys manually.
- Do not expose streamer publicly without authentication.
- Avoid logging API keys or pairing tokens.
- Rotate credentials if you suspect a leak.

See `../SECURITY.md` for vulnerability reporting.
