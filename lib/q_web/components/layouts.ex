defmodule QWeb.Layouts do
  use QWeb, :html

  embed_templates "layouts/*"
end
