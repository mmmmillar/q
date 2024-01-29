defmodule Q.Repo.Migrations.Jobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :status, :string, default: "pending"
      timestamps()
    end
  end
end
