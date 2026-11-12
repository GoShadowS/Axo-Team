<script lang="ts">
  import { renderMarkdown } from '../lib/markdown';

  interface Props {
    source: string;
  }

  let { source }: Props = $props();

  // renderMarkdown вырезает всё исполняемое (DOMPurify), поэтому {@html} здесь безопасен.
  const html = $derived(renderMarkdown(source));
</script>

<div class="prose">{@html html}</div>
