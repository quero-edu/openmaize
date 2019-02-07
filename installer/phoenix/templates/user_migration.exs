defmodule <%= base %>.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :username, :string
      add :password_hash, :string<%= if confirm do %>
      add :confirmed_at, :utc_datetime_usec
      add :confirmation_token, :string
      add :confirmation_sent_at, :utc_datetime_usec
      add :reset_token, :string
      add :reset_sent_at, :utc_datetime_usec<% end %>

      timestamps()
    end

    create unique_index :users, [:email]
  end
end
