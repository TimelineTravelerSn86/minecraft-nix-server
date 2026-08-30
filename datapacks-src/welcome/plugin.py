from beet import Context, Function


def beet_default(ctx: Context):
    """
    Greet each player once per join, the first time they're seen.
    """

    ctx.data["welcome:tick"] = Function(
        [
            'tellraw @s {"text": "Welcome to NixOS server!", "color":"gold", "bold":"true"}'
        ],
        tags=["minecraft:tick"],
    )

    ctx.data["welcome:greet"] = Function(
        [
            'tellraw @s {"text":"Welcome to the server!","color":"gold","bold":true}',
            "tag @s add welcomed",
        ]
    )
