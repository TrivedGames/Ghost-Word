@tool
extends EditorPlugin

var import_button: Button
var file_dialog: FileDialog
var progress_popup: AcceptDialog
var progress_bar: ProgressBar
var all_paths: PackedStringArray = []
var current_index := 0

func _enter_tree():
	import_button = Button.new()
	import_button.text = "📦 Import"
	import_button.tooltip_text = "Pick and copy files or folders into project"
	import_button.connect("pressed", Callable(self, "_on_button_pressed"))
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, import_button)

	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_ANY
	file_dialog.size = Vector2i(900,500)
	file_dialog.filters = ["*.* ; All Files"]
	file_dialog.current_dir = "/storage/emulated/0/"
	file_dialog.connect("file_selected", Callable(self, "_on_files_selected"))
	file_dialog.connect("files_selected", Callable(self, "_on_files_selected"))
	file_dialog.connect("dir_selected", Callable(self, "_on_dir_selected"))
	get_editor_interface().get_base_control().add_child(file_dialog)

	progress_popup = AcceptDialog.new()
	progress_popup.title = "Importing..."
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_popup.add_child(progress_bar)
	get_editor_interface().get_base_control().add_child(progress_popup)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, import_button)
	import_button.queue_free()
	file_dialog.queue_free()
	progress_popup.queue_free()

func _on_button_pressed():
	file_dialog.show()

func _on_files_selected(paths):
	if paths.is_empty():
		return
	all_paths = paths if typeof(paths) == 28 else [paths]
	await get_tree().process_frame
	progress_popup.popup_centered()
	await _import_all()

func _on_dir_selected(path: String):
	all_paths = [path]
	await get_tree().process_frame
	progress_popup.popup_centered()
	await _import_all()

func _import_all():
	var total := all_paths.size()
	for i in range(total):
		var p = all_paths[i]
		var dir_info = DirAccess.open(p)
		if dir_info:
			print("it's directory ")
			copy_directory(p, "res://" + p.get_file())
		else:
			print("it's fule")
			_copy_file_to_project(p, "res://" + p.get_file())

		progress_bar.value = int(((i + 1) / float(total)) * 100)
		await get_tree().process_frame

	progress_popup.hide()
	_refresh_filesystem()

func copy_directory(source_dir: String, dest_dir: String):
	var dir := DirAccess.open(source_dir)
	if dir == null:
		push_error("Cannot open directory: " + source_dir)
		return
	
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dest_dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest_dir))

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var src_path = source_dir.path_join(file_name)
		var dst_path = dest_dir.path_join(file_name)

		if dir.current_is_dir():
			copy_directory(src_path, dst_path)
		else:
			var err = DirAccess.copy_absolute(ProjectSettings.globalize_path(src_path), ProjectSettings.globalize_path(dst_path))
			if err != OK:
				push_error("Failed to copy file: " + src_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _copy_file_to_project(source_path: String, dest_path: String):
	var src = FileAccess.open(source_path, FileAccess.READ)
	if src == null:
		push_error("❌ Failed to open file: " + source_path)
		return
	var dst = FileAccess.open(dest_path, FileAccess.WRITE)
	if dst == null:
		push_error("❌ Cannot write to: " + dest_path)
		src.close()
		return
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	print("✅ Copied file:", source_path.get_file())

func _refresh_filesystem():
	var fs = get_editor_interface().get_resource_filesystem()
	fs.scan()
	print("🔄 Filesystem refreshed after importing.")
