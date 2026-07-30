# 0001. Fixed Primary Wide Lens

## Context

Modern iPhones have multiple lenses (Ultra Wide, Wide, Telephoto) and users expect to be able to pinch-to-zoom, which digitally zooms or seamlessly switches between lenses. However, digital zoom severely degrades image quality, and seamlessly switching physical lenses relies heavily on Apple's computational photography processing to smooth the transition. 

## Decision

We will lock the camera exclusively to the primary wide lens and completely disable pinch-to-zoom or any form of digital zoom. The app will behave like a fixed prime-lens camera.

## Consequences

- **Purity:** We guarantee that images are not degraded by digital zoom or computational lens-switching logic.
- **Simplicity:** Eliminates the need for zoom UI controls or gesture recognizers.
- **Limitation:** The user cannot zoom in on distant subjects or zoom out for ultra-wide shots, strictly limiting the compositional freedom to a ~26mm equivalent field of view.
