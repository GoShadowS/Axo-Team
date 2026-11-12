<script lang="ts">
  interface Props {
    size?: number;
  }

  let { size = 28 }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true" focusable="false">
  <g stroke="var(--axo-accent)" stroke-width="5" stroke-linecap="round">
    <path d="M14 26 5 16M12 34 2 32M15 42 6 49" />
    <path d="M50 26l9-10M52 34l10-2M49 42l9 7" />
  </g>
  <rect x="12" y="16" width="40" height="36" rx="18" fill="var(--axo-accent-strong)" />
  <circle cx="24" cy="32" r="3.5" fill="var(--axo-accent-contrast)" />
  <circle cx="40" cy="32" r="3.5" fill="var(--axo-accent-contrast)" />
  <path d="M26 41q6 5 12 0" fill="none" stroke="var(--axo-accent-contrast)" stroke-width="2.5" stroke-linecap="round" />
</svg>
