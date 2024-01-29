defmodule Q.Repo.Migrations.AddNewJobNotify do
  use Ecto.Migration

  def change do
    execute """
    CREATE OR REPLACE FUNCTION new_job_notify()
      RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        PERFORM pg_notify('new_job', row_to_json(NEW)::text);
        RETURN NEW;
      END;
    $$;
    """

    execute """
    CREATE TRIGGER new_job_notify_trigger
      AFTER INSERT
      ON jobs
      FOR EACH ROW
      EXECUTE PROCEDURE new_job_notify();
    """
  end
end
