<script lang="ts">
  import { href } from '../lib/routes';
</script>

<section class="section">
  <div class="container">
    <h1 class="page-title">Страница не найдена</h1>
    <p class="lead">Такого адреса нет. Возможно, проект переименован или ссылка устарела.</p>
    <p><a class="button" href={href({ name: 'projects' })}>Открыть каталог проектов</a></p>
  </div>
</section>
