#ifndef _SHADERS_CONFIG_H
	#define _SHADERS_CONFIG_H

/* console commands
	r2_ambient_occ [on/off]
	r2_sun_shafts [off/low/medium/high]
	r2_old_sun_shafts [off/low/high]
	r2_pom [off/low/medium/high/maximum]
*/

/////////////////////////////////////////////////////////////
// improved parallax occlusion mapping
//	#define POM_PARALLAX_OFFSET float(0.02)			// смещение. Чем больше, тем дальше будут выступать кирпичи.

/////////////////////////////////////////////////////////////
// Вода
	#define SW_USE_FOAM								// включить "пену" прибоя
	#define SW_FOAM_THICKNESS float (0.04)			// толщина "пены"
	#define SW_WATER_INTENSITY float (1.0)			// глубина цвета воды

/////////////////////////////////////////////////////////////
// Волны по траве
	#define USE_GRASS_WAVE							// включить "волны" от ветра по траве
	#define GRASS_WAVE_POWER float(1.1)				// "яркость", заметность волн
	#define GRASS_WAVE_FREQ float(0.4)				// частота появления волн

/////////////////////////////////////////////////////////////
// implementation by daemonjax
	#define AO_CHECK 1					// номер предустановки качества

/////////////////////////////////////////////////////////////
// Саншафты ака GodRays
	#define SS_QUALITY 2			// номер предустановки качества
	#define SS_LENGHT float(1.8)  //(0.9)				// длина лучей. Работает совместно с погодным конфигом
	#define SS_INTENSITY float(1.4) //(0.7)						// интенсивность лучей. Работает совместно с погодным конфигом
	#define SS_BLEND_FACTOR float(0.45)			// фактор смешивания с рассеянным светом
	#define SS_OUTCOLOR_COEFF float3(0.3,0.3,0.3)					// сколько добавить к out_color если выключено смешивание с рассянным светом
	#define SS_BLUR					// включить смешивание с рассеянным светом
//	#define SS_DUST							// включить пыль в саншафтах
	#define SS_DUST_SPEED float(0.4)		// скорость частиц пыли 
	#define SS_DUST_INTENSITY float(4.0)	// яркость пылинок
	#define SS_DUST_DENSITY float(1.0)		// плотность частиц пыли 
	#define SS_DUST_SIZE float(0.7)			// размер пылинок	

/////////////////////////////////////////////////////////////
// Setting local light
	#define ECB_LL_DIST 1.2f			// дальность освещения ламп и костров
	#define ECB_LL_BRIGHTNESS .7f							// яркость освещения ламп и костров

/////////////////////////////////////////////////////////////
// misc lighting
//	#define TEX_CONT				// increase texture contrast for diffuse lighting. Enables use of the lines below
	#define TEX_CONT_COEF float(0.9)			// diffuse (ambient) lighting brightness multiplier.  Higher is brighter
	#define TEX_CONT_ADD float(0.0)			// diffuse lighting bightness increase amount. Higher is brighter. You're probably better off just changing the multiplier above

/////////////////////////////////////////////////////////////
// Parallax Occlusion Mapping
	#define POM_QUALITY 4				// номер предустановки качества
	#define PARALLAX_OFFSET float(0.01)			// height of extruded surface

/////////////////////////////////////////////////////////////
// Shadow
	#define ECB_SHADOW_KERNEL .9f			// ширина одиночных полосок-переходов в тенях
	#define ECB_SHADOW_STEPS 2					// количество полосок перехода тени от светлой к темной (integer)

/////////////////////////////////////////////////////////////
// Sky4CE sunshafts
//	#define SSO_QUALITY 2		// номер предустановки качества
	#define SSO_INTENSITY float(1.4) //(0.7)			// интенсивность лучей. Работает совместно с погодным конфигом 
	#define SS_CONTRAST float(0.9)			// контрастность лучей. Чем больше значение, тем темнее фоновое окружение и светлее лучи

#endif // _SHADERS_CONFIG_H