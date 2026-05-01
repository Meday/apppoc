<script lang="ts">
  const API_URL = "http://127.0.0.1:8080/api/tasks";

  interface Task {
    id?: number;
    title: string;
    status: string;
  }

  let tasks = $state<Task[]>([]);
  let newTitle = $state("");
  let newStatus = $state("todo");
  let editingTask = $state<Task | null>(null);
  let error = $state("");

  async function fetchTasks() {
    try {
      const res = await fetch(API_URL, {
        headers: { Accept: "application/json" },
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      tasks = await res.json();
      error = "";
    } catch (e) {
      error = `Impossible de charger les tâches : ${e}`;
    }
  }

  async function createTask(event: Event) {
    event.preventDefault();
    if (!newTitle.trim()) return;
    try {
      const res = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({ title: newTitle.trim(), status: newStatus }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      newTitle = "";
      newStatus = "todo";
      await fetchTasks();
    } catch (e) {
      error = `Erreur création : ${e}`;
    }
  }

  async function deleteTask(id: number) {
    try {
      const res = await fetch(`${API_URL}/${id}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      await fetchTasks();
    } catch (e) {
      error = `Erreur suppression : ${e}`;
    }
  }

  function startEdit(task: Task) {
    editingTask = { ...task };
  }

  function cancelEdit() {
    editingTask = null;
  }

  async function saveEdit(event: Event) {
    event.preventDefault();
    if (!editingTask) return;
    try {
      const res = await fetch(`${API_URL}/${editingTask.id}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/merge-patch+json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          title: editingTask.title,
          status: editingTask.status,
        }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      editingTask = null;
      await fetchTasks();
    } catch (e) {
      error = `Erreur modification : ${e}`;
    }
  }

  $effect(() => {
    fetchTasks();
  });
</script>

<main class="container">
  <h1>Gestion des Tâches</h1>

  {#if error}
    <p class="error">{error}</p>
  {/if}

  <form class="create-form" onsubmit={createTask}>
    <input
      type="text"
      placeholder="Titre de la tâche..."
      bind:value={newTitle}
      required
    />
    <select bind:value={newStatus}>
      <option value="todo">À faire</option>
      <option value="in_progress">En cours</option>
      <option value="done">Terminé</option>
    </select>
    <button type="submit">Ajouter</button>
  </form>

  <div class="task-list">
    {#each tasks as task (task.id)}
      <div class="task-item">
        {#if editingTask && editingTask.id === task.id}
          <form class="edit-form" onsubmit={saveEdit}>
            <input type="text" bind:value={editingTask.title} required />
            <select bind:value={editingTask.status}>
              <option value="todo">À faire</option>
              <option value="in_progress">En cours</option>
              <option value="done">Terminé</option>
            </select>
            <button type="submit" class="btn-save">✓</button>
            <button type="button" class="btn-cancel" onclick={cancelEdit}>✕</button>
          </form>
        {:else}
          <span class="task-title">{task.title}</span>
          <span class="task-status badge-{task.status}">{task.status}</span>
          <div class="task-actions">
            <button class="btn-edit" onclick={() => startEdit(task)}>✎</button>
            <button class="btn-delete" onclick={() => deleteTask(task.id!)}>🗑</button>
          </div>
        {/if}
      </div>
    {:else}
      <p class="empty">Aucune tâche pour le moment.</p>
    {/each}
  </div>
</main>

<style>
  :root {
    font-family: Inter, Avenir, Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 24px;
    font-weight: 400;
    color: #0f0f0f;
    background-color: #f6f6f6;
  }

  .container {
    max-width: 640px;
    margin: 0 auto;
    padding: 2rem 1rem;
  }

  h1 {
    text-align: center;
    margin-bottom: 1.5rem;
  }

  .error {
    color: #dc3545;
    background: #f8d7da;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    margin-bottom: 1rem;
  }

  .create-form {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
  }

  .create-form input {
    flex: 1;
  }

  input, select, button {
    border-radius: 6px;
    border: 1px solid #ccc;
    padding: 0.5rem 0.75rem;
    font-size: 0.9rem;
    font-family: inherit;
  }

  button {
    cursor: pointer;
    background: #396cd8;
    color: white;
    border: none;
    font-weight: 600;
  }

  button:hover {
    background: #2a56b0;
  }

  .task-list {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .task-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem 1rem;
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  }

  .task-title {
    flex: 1;
    font-weight: 500;
  }

  .task-status {
    font-size: 0.8rem;
    padding: 0.2rem 0.6rem;
    border-radius: 12px;
    font-weight: 600;
    text-transform: uppercase;
  }

  .badge-todo { background: #e2e8f0; color: #475569; }
  .badge-in_progress { background: #dbeafe; color: #1d4ed8; }
  .badge-done { background: #d1fae5; color: #059669; }

  .task-actions {
    display: flex;
    gap: 0.25rem;
  }

  .btn-edit, .btn-cancel {
    background: #6b7280;
    padding: 0.3rem 0.5rem;
    font-size: 0.85rem;
  }

  .btn-delete {
    background: #dc3545;
    padding: 0.3rem 0.5rem;
    font-size: 0.85rem;
  }

  .btn-save {
    background: #059669;
    padding: 0.3rem 0.5rem;
    font-size: 0.85rem;
  }

  .edit-form {
    display: flex;
    gap: 0.5rem;
    width: 100%;
    align-items: center;
  }

  .edit-form input {
    flex: 1;
  }

  .empty {
    text-align: center;
    color: #888;
    padding: 2rem;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      color: #f6f6f6;
      background-color: #1a1a1a;
    }

    .task-item {
      background: #2f2f2f;
    }

    input, select {
      background: #3a3a3a;
      color: #f6f6f6;
      border-color: #555;
    }

    .error {
      background: #5a2020;
      color: #fca5a5;
    }
  }
</style>
