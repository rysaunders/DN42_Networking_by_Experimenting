# Part 1: From Host to Router

Part 1 builds the mental model needed before building Pocket Internet.

By the end of this part, the reader should be able to:

- Predict which interface a packet will leave.
- Explain basic source address selection.
- Read route tables and identify connected, default, and blackhole routes.
- Explain why explicit routes matter before dynamic routing is introduced.

The labs are local and disposable. They start with Linux routing, then add BIRD, BGP, services, and WireGuard before any public DN42 state enters the picture.
