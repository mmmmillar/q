defmodule Q.Repo.Migrations.AddRetryCount do
  use Ecto.Migration

  def change do
    alter table("jobs") do
      add :retries, :integer, default: 0
    end
  end
end
