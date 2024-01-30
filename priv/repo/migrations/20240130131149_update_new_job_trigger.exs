defmodule Q.Repo.Migrations.UpdateNewJobTrigger do
  use Ecto.Migration

  def change do
    execute """
    DROP TRIGGER IF EXISTS new_job_notify_trigger ON jobs;
    """

    execute """
    CREATE TRIGGER new_job_notify_trigger
      AFTER INSERT OR UPDATE
      ON jobs
      FOR EACH ROW
      WHEN (NEW.status = 'pending')
      EXECUTE PROCEDURE new_job_notify();
    """
  end
end
