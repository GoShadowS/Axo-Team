<script lang="ts">
  import Catalog from '../components/Catalog.svelte';
</script>

<section class="section">
  <div class="container">
    <h1 class="page-title">Проекты</h1>
    <p class="lead">Каталог всех проектов. Откройте карточку, чтобы прочитать описание и документацию.</p>
    <Catalog />
  </div>
</section>

<style>
  .lead {
    margin: 0 0 1.75rem;
  }
</style>
