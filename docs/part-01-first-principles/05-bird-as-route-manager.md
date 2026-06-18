# BIRD as a Route Manager

!!! note "Planned chapter"
    This chapter is the next structural gap to fill. It is intentionally present in the navigation so the learning path no longer jumps from static routing directly into full BGP configuration.

This chapter will teach BIRD before BGP.

The current BGP chapter asks BIRD to do several jobs at once:

- keep its own view of routes,
- decide which routes are usable,
- exchange routes with neighbors,
- apply import and export filters,
- install selected routes into the Linux kernel.

That is too much to meet for the first time inside a four-router BGP lab.

This chapter will slow down and isolate BIRD as a local route manager. The reader should leave able to explain:

- BIRD has its own route table,
- BIRD knowing a route is not the same thing as Linux forwarding with that route,
- `protocol direct` can learn routes from local interfaces,
- `protocol static` can define routes inside BIRD,
- `protocol kernel` is how BIRD can install selected routes into Linux,
- filters exist before public peers exist.

## Why This Chapter Exists

Static routing made route maintenance feel manual. BGP will automate route exchange between routers. BIRD sits between those ideas.

Before BIRD speaks to another router, it can already manage routes locally. That smaller job deserves its own chapter.

## Next Draft Work

Issue #40 will turn this placeholder into a full manual-first chapter with:

- a small local lab,
- annotated BIRD config,
- `birdc` inspection commands,
- kernel route checks,
- "what this proves / what this does not prove" callouts,
- reader knowledge ledger updates,
- technical review for the BIRD examples.

Until then, continue to [BGP Before DN42](06-bgp-before-dn42.md) for the current tested BGP lab.
