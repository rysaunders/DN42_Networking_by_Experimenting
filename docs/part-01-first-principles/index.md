# Part 1: Pocket Internet Foundations

Part 1 builds the local model for Pocket Internet before any public DN42 state enters the picture.

By the end of this part, the reader should be able to:

- Predict which interface a packet will leave.
- Explain basic source address selection.
- Read route tables and identify connected, default, and BGP-learned routes.
- Explain why explicit routes matter before dynamic routing is introduced.
- Explain why BIRD and BGP are useful after static routes become tedious.
- Operate a simple service inside the lab.
- Explain how a WireGuard tunnel can behave like a point-to-point link.

The labs are local and disposable. They start with Linux routing, then add BIRD, BGP, services, and WireGuard before any public DN42 state enters the picture.

Chapter 05 is currently a planned bridge chapter. It exists to make the structure honest: the book needs to teach BIRD as a local route manager before asking readers to absorb the full BGP lab. The tested BGP lab remains in Chapter 06.
