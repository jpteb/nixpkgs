{
  lib,
  mkDerivation,
  stdenv,
  zlib,
  defaultMakeFlags,
  coreutils,
  cctools-port,
  install,
  bsdSetupHook,
  netbsdSetupHook,
  makeMinimal,
  rsync,
  _mainLibcExtraPaths,
  version,
}:

mkDerivation (
  let
    commonDeps = [ zlib ];
  in
  {
    path = "tools/compat";

    setupHooks = [
      ../../../../../build-support/setup-hooks/role.bash
      ./compat-setup-hook.sh
    ];

    preConfigure = ''
      make include/.stamp configure nbtool_config.h.in defs.mk.in
    '';

    configurePlatforms = [
      "build"
      "host"
    ];
    configureFlags =
      [ "--cache-file=config.cache" ]
      ++ lib.optionals stdenv.hostPlatform.isMusl [
        # We include this header in our musl package only for legacy
        # compatibility, and compat works fine without it (and having it
        # know about sys/cdefs.h breaks packages like glib when built
        # statically).
        "ac_cv_header_sys_cdefs_h=no"
      ];

    nativeBuildInputs = commonDeps ++ [
      bsdSetupHook
      netbsdSetupHook
      makeMinimal
      rsync
    ];

    buildInputs = commonDeps;

    # temporarily use gnuinstall for bootstrapping
    # bsdinstall will be built later
    makeFlags =
      defaultMakeFlags
      ++ [
        "INSTALL=${coreutils}/bin/install"
        "DATADIR=$(out)/share"
        # Can't sort object files yet
        "LORDER=echo"
        "TSORT=cat"
        # Can't process man pages yet
        "MKSHARE=no"
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        # GNU objcopy produces broken .a libs which won't link into dependers.
        # Makefiles only invoke `$OBJCOPY -x/-X`, so cctools strip works here.
        "OBJCOPY=${cctools-port}/bin/strip"
      ];
    RENAME = "-D";

    passthru.tests = {
      netbsd-install = install;
    };

    patches = [
      ./compat-cxx-safe-header.patch
      ./compat-dont-configure-twice.patch
      ./compat-no-force-native.patch
    ];

    preInstall = ''
      makeFlagsArray+=('INSTALL_FILE=''${INSTALL} ''${COPY} ''${PRESERVE} ''${RENAME}')
      makeFlagsArray+=('INSTALL_DIR=''${INSTALL} -d')
      makeFlagsArray+=('INSTALL_SYMLINK=''${INSTALL} ''${SYMLINK} ''${RENAME}')
    '';

    postInstall =
      ''
        # why aren't these installed by netbsd?
        install -D compat_defs.h $out/include/compat_defs.h
        install -D $BSDSRCDIR/include/cdbw.h $out/include/cdbw.h
        install -D $BSDSRCDIR/sys/sys/cdbr.h $out/include/cdbr.h
        install -D $BSDSRCDIR/sys/sys/featuretest.h \
                   $out/include/sys/featuretest.h
        install -D $BSDSRCDIR/sys/sys/md5.h $out/include/md5.h
        install -D $BSDSRCDIR/sys/sys/rmd160.h $out/include/rmd160.h
        install -D $BSDSRCDIR/sys/sys/sha1.h $out/include/sha1.h
        install -D $BSDSRCDIR/sys/sys/sha2.h $out/include/sha2.h
        install -D $BSDSRCDIR/sys/sys/queue.h $out/include/sys/queue.h
        install -D $BSDSRCDIR/include/vis.h $out/include/vis.h
        install -D $BSDSRCDIR/include/db.h $out/include/db.h
        install -D $BSDSRCDIR/include/netconfig.h $out/include/netconfig.h
        install -D $BSDSRCDIR/include/utmpx.h $out/include/utmpx.h
        install -D $BSDSRCDIR/include/tzfile.h $out/include/tzfile.h
        install -D $BSDSRCDIR/sys/sys/tree.h $out/include/sys/tree.h
        install -D $BSDSRCDIR/include/nl_types.h $out/include/nl_types.h
        install -D $BSDSRCDIR/include/stringlist.h $out/include/stringlist.h

        # Collapse includes slightly to fix dangling reference
        install -D $BSDSRCDIR/common/include/rpc/types.h $out/include/rpc/types.h
        sed -i '1s;^;#include "nbtool_config.h"\n;' $out/include/rpc/types.h
      ''
      + lib.optionalString stdenv.isDarwin ''
        mkdir -p $out/include/ssp
        touch $out/include/ssp/ssp.h
      ''
      + ''
        mkdir -p $out/lib/pkgconfig
        substitute ${./libbsd-overlay.pc} $out/lib/pkgconfig/libbsd-overlay.pc \
          --subst-var-by out $out \
          --subst-var-by version ${version}
      '';
    extraPaths = [
      "common"
      "include"
      "lib/libc"
      "lib/libutil"
      "external/bsd/flex"
      "sys"
      "common/include/rpc/types.h"
    ] ++ _mainLibcExtraPaths;
  }
)
