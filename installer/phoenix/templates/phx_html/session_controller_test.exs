defmodule <%= base %>.SessionControllerTest do
  use <%= base %>.ConnCase

  import <%= base %>.TestHelpers

  @valid_attrs %{email: "robin@mail.com", password: "mangoes&g0oseberries"}
  @invalid_attrs %{email: "robin@mail.com", password: "maaaangoes&g00zeberries"}

  setup %{conn: conn} do
    conn = conn |> bypass_through(<%= base %>.Router, :browser) |> get("/")<%= if confirm do %>
    add_user("arthur")
    confirmed = add_user_confirmed("robin")

    {:ok, %{conn: conn, confirmed: confirmed}}<% else %>
    user = add_user("robin")

    {:ok, %{conn: conn, user: user}}<% end %>
  end

  test "login succeeds", %{conn: conn} do
    conn = post conn, session_path(conn, :create), session: @valid_attrs
    assert redirected_to(conn) == user_path(conn, :index)
  end

  test "login fails", %{conn: conn} do
    conn = post conn, session_path(conn, :create), session: @invalid_attrs
    assert redirected_to(conn) == session_path(conn, :new)
  end<%= if confirm do %>

  test "logout succeeds", %{conn: conn, confirmed: confirmed} do
    conn = conn |> put_session(:user_id, confirmed.id) |> send_resp(:ok, "/")
    conn = delete conn, session_path(conn, :delete, confirmed)<% else %>

  test "logout succeeds", %{conn: conn, user: user} do
    conn = conn |> put_session(:user_id, user.id) |> send_resp(:ok, "/")
    conn = delete conn, session_path(conn, :delete, user)<% end %>
    assert redirected_to(conn) == page_path(conn, :index)
  end<%= if confirm do %>

  test "confirmation succeeds for correct key", %{conn: conn} do
    email = "arthur@mail.com"
    key = "pu9-VNdgE8V9qZo19rlcg3KUNjpxuixg"
    conn = get(conn, session_path(conn, :confirm_email, email: email, key: key))
    assert conn.private.phoenix_flash["info"] =~ "Account confirmed"
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "confirmation fails for incorrect key", %{conn: conn} do
    email = "arthur@mail.com"
    key = "pu9-VNdgE8V9QzO19RLCG3KUNjpxuixg"
    conn = get(conn, session_path(conn, :confirm_email, email: email, key: key))
    assert conn.private.phoenix_flash["error"] =~ "Invalid credentials"
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "confirmation fails for incorrect email", %{conn: conn} do
    email = "gerald@mail.com"
    key = "pu9-VNdgE8V9qZo19rlcg3KUNjpxuixg"
    conn = get(conn, session_path(conn, :confirm_email, email: email, key: key))
    assert conn.private.phoenix_flash["error"] =~ "Invalid credentials"
    assert redirected_to(conn) == session_path(conn, :new)
  end<% end %>
end
