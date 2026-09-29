if (!("EX" in getroottable())) { ::EX <- {} }
if (!("shared" in ::EX)) { ::EX.shared <- {} }

// shared engine art, as bare handles; ask ::UI.imageSize for a size, it is only known once drawn
::EX.shared.images <- {
    tileable_scroll = ::UI.loadSpriteSet(["SCROLL_TOP_LEFT", "SCROLL_TOP_CENTER", "SCROLL_TOP_RIGHT",
                                          "SCROLL_MID_LEFT", "SCROLL_MID", "SCROLL_MID_RIGHT",
                                          "SCROLL_BOTTOM_LEFT", "SCROLL_BOTTOM_CENTER", "SCROLL_BOTTOM_RIGHT"],
                                         ::UI.PAGE_SHARED),

    tileable_panel  = ::UI.loadSpriteSet(["FRAME_BORDER_TL", "FRAME_BORDER_TOP", "FRAME_BORDER_TR",
                                          "FRAME_BORDER_L", "TILEABLE_FRAME_BG", "FRAME_BORDER_R",
                                          "FRAME_BORDER_BL", "FRAME_BORDER_BOTTOM", "FRAME_BORDER_BR"],
                                         ::UI.PAGE_SHARED),

    seal            = ::UI.loadSprite("SEAL_BUTTON_IMAGE", ::UI.PAGE_SHARED).img,
}
