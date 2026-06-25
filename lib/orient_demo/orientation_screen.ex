defmodule OrientDemo.OrientationScreen do
  @moduledoc """
  Exercises `Mob.Device` orientation: live detection via the `:display`
  subscription, and `lock_orientation/1` / `unlock_orientation/0`.
  """
  use Mob.Screen

  @locks [
    {"Lock Portrait", :portrait},
    {"Lock Landscape (either)", :landscape},
    {"Lock Landscape Left", :landscape_left},
    {"Lock Landscape Right", :landscape_right},
    {"Lock Portrait Upside Down", :portrait_upside_down}
  ]

  def mount(_params, _session, socket) do
    Mob.Device.subscribe(:display)

    socket =
      socket
      |> Mob.Socket.assign(:orientation, Mob.Device.orientation())
      |> Mob.Socket.assign(:locked, nil)

    {:ok, socket}
  end

  def render(assigns) do
    %{
      type: :scroll,
      props: %{background: :background},
      children: [
        %{
          type: :column,
          props: %{background: :background, padding: :space_md, fill_width: true},
          children:
            [
              text("📱  Orientation", :xl, :on_background, :space_sm),
              %{type: :spacer, props: %{size: 16}, children: []},
              text("Current orientation", :sm, :muted, 4),
              text(label(assigns.orientation), :xl, :primary, :space_sm),
              text("Lock: #{label(assigns.locked) || "none (follow sensor)"}", :sm, :muted, 4),
              %{type: :spacer, props: %{size: 8}, children: []},
              button("Re-read orientation/0", :refresh),
              %{type: :spacer, props: %{size: 20}, children: []},
              %{type: :divider, props: %{color: :border}, children: []},
              %{type: :spacer, props: %{size: 16}, children: []}
            ] ++
              lock_buttons() ++
              [
                %{type: :spacer, props: %{size: 16}, children: []},
                button("Unlock (follow sensor)", :unlock)
              ]
        }
      ]
    }
  end

  defp lock_buttons do
    Enum.flat_map(@locks, fn {label, orientation} ->
      [button(label, {:lock, orientation}), %{type: :spacer, props: %{size: 8}, children: []}]
    end)
  end

  defp button(label, tag) do
    tap = {self(), tag}

    ~MOB(<Button text={label} background={:primary} text_color={:on_primary} text_size={:md} fill_width={true} padding={:space_md} on_tap={tap} />)
  end

  defp text(content, size, color, padding) do
    %{type: :text, props: %{text: content, text_size: size, text_color: color, padding: padding}, children: []}
  end

  def handle_info({:tap, :refresh}, socket) do
    {:noreply, Mob.Socket.assign(socket, :orientation, Mob.Device.orientation())}
  end

  def handle_info({:tap, :unlock}, socket) do
    :ok = Mob.Device.unlock_orientation()
    {:noreply, Mob.Socket.assign(socket, :locked, nil)}
  end

  def handle_info({:tap, {:lock, orientation}}, socket) do
    case Mob.Device.lock_orientation(orientation) do
      :ok -> {:noreply, Mob.Socket.assign(socket, :locked, orientation)}
      {:error, :invalid} -> {:noreply, socket}
    end
  end

  def handle_info({:mob_device, :orientation_changed, orientation}, socket) do
    {:noreply, Mob.Socket.assign(socket, :orientation, orientation)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp label(nil), do: nil
  defp label(orientation), do: orientation |> to_string() |> String.replace("_", " ")
end
