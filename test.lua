require("gitlinker").setup({
  router = {
    browse = {
      ["^github%.your%.host"] = "https://github.your.host/"
        .. "{_A.USER}/"
        .. "{_A.REPO}/blob/"
        .. "{_A.REV}/"
        .. "{_A.FILE}"
        .. "#L{_A.LSTART}"
        .. "{_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or ''}",
    },
  },
})
