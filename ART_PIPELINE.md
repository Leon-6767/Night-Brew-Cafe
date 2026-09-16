# Night Brew Cafe 美术替换流程

所有可替换视觉资源在 `res://assets/`：角色位于 `characters/`，家具位于 `furniture/`，环境位于 `environment/`，UI 位于 `ui/`，特效位于 `vfx/`。逻辑脚本通过 `scripts/visual_catalog.gd` 按职业、顾客类型或家具 ID 查询贴图；不要在经营脚本中写入贴图路径。

## 角色

替换 `staff_*_placeholder.svg` 或 `customer_placeholder.svg` 为 PNG／SpriteSheet，并在 `VisualCatalog` 或 `CharacterVisual.tscn` 的 Sprite2D 中替换 Texture。推荐单帧 96×128 像素、角色脚底在画布底边中点 `(48, 120)`；四方向 SpriteSheet 推荐每行 4 帧、每帧 96×128。`CharacterVisual` 已预留 Shadow、Body、Head、RoleBadge、StateBubble 与 AnimationPlayer 节点。

## 家具与环境

家具贴图入口由 `FurnitureVisual.tscn` 的 `texture_override` 或 `VisualCatalog.FURNITURE_TEXTURES` 提供。小桌推荐 128×96、吧台 256×160、咖啡机 112×128；等距物件的脚底／接地锚点应放在贴图底部中点。替换图片不会影响格子占用、Y 排序、镜头或存档。

## 动画与特效

角色预留 `idle`、`walk`、`make`、`deliver`、`clean` AnimationPlayer 动画名。正式动画可直接在 `CharacterVisual.tscn` 增加对应轨道；不要改动员工任务脚本。咖啡机蒸汽贴图放在 `assets/vfx/`，付款金币图标放在 `assets/ui/icons/`。

## 新资源登记

新增角色或家具时：添加贴图 → 在 `VisualCatalog` 添加 ID 映射 → 必要时在 `FurnitureVisual` Inspector 指定 `texture_override`。经营逻辑、坐标、AI 和保存格式无需修改。
