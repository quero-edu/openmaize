Logger.configure(level: :info)
alias Openmaize.TestRepo

Application.put_env(:openmaize, :pg_test_url,
  "ecto://" <> (System.get_env("PG_URL") || "postgres:postgres@localhost")
)

Application.put_env(:openmaize, TestRepo,
  adapter: Ecto.Adapters.Postgres,
  url: Application.get_env(:openmaize, :pg_test_url) <> "/openmaize_test",
  pool: Ecto.Adapters.SQL.Sandbox)

defmodule Openmaize.TestRepo do
  use Ecto.Repo,
    otp_app: :openmaize,
    adapter: Ecto.Adapters.Postgres
end

defmodule UsersMigration do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :username, :string
      add :phone, :string
      add :password_hash, :string
      add :role, :string
      add :confirmed_at, :utc_datetime_usec
      add :confirmation_token, :string
      add :confirmation_sent_at, :utc_datetime_usec
      add :reset_token, :string
      add :reset_sent_at, :utc_datetime_usec
      add :otp_required, :boolean
      add :otp_secret, :string
      add :otp_last, :integer
    end

    create unique_index :users, [:email]
  end
end

defmodule Openmaize.TestUser do
  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string
    field :phone, :string
    field :role, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :confirmed_at, :utc_datetime_usec
    field :confirmation_token, :string
    field :confirmation_sent_at, :utc_datetime_usec
    field :reset_token, :string
    field :reset_sent_at, :utc_datetime_usec
    field :otp_required, :boolean
    field :otp_secret, :string
    field :otp_last, :integer
  end

  def changeset(struct, params \\ :empty) do
    struct
    |> cast(params, [:email, :username, :role, :phone, :confirmed_at,
      :otp_required, :otp_secret, :otp_last])
    |> validate_required([:email])
    |> validate_length(:email, min: 1, max: 100)
    |> unique_constraint(:email)
  end

  def auth_changeset(struct, params) do
    struct
    |> changeset(params)
    |> Openmaize.Database.add_password_hash(params)
  end

  def confirm_changeset(struct, params, key) do
    struct
    |> auth_changeset(params)
    |> Openmaize.Database.add_confirm_token(key)
  end
end

defmodule Openmaize.TestCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
  end
end

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(TestRepo, :temporary)

_   = Ecto.Adapters.Postgres.storage_down(TestRepo.config)
:ok = Ecto.Adapters.Postgres.storage_up(TestRepo.config)

{:ok, _pid} = TestRepo.start_link

:ok = Ecto.Migrator.up(TestRepo, 0, UsersMigration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
