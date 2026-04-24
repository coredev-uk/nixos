{ inputs, meta, ... }:
{
  programs.opencode = {
    enable = true;

    # Remove override when https://github.com/anomalyco/opencode/issues/23256 is resolved
    package = inputs.opencode.packages.${meta.system}.opencode.overrideAttrs (old: {
      preBuild = (old.preBuild or "") + ''
        substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
          --replace-fail 'const prettier = await import("prettier")' 'const prettier: any = { format: async (s: string) => s }' \
          --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
          --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
      '';
    });
  };
}
