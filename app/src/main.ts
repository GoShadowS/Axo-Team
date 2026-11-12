import '@axo/ui/tokens.css';
import '@axo/ui/base.css';
import './app.css';
import { mount } from 'svelte';
import App from './App.svelte';
import { openExternalLinksInBrowser } from './external-links';

openExternalLinksInBrowser();

const target = document.getElementById('app');
if (!target) throw new Error('Не найден элемент #app');

export default mount(App, { target });
