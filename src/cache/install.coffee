import { install, caches } from "undici"

install()
globalThis?.caches = caches
